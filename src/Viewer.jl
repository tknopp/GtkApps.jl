using Gtk.ShortNames, Gtk.GConstants
using Winston
using RawFile
import Color

export viewer, ImageViewer

type ImageViewer <: Gtk.GtkWindow
  handle::Ptr{Gtk.GObject}
end

const uifile = joinpath( dirname(Base.source_path()), "Viewer.ui" )

function ImageViewer()

  println( uifile )

  c1 = @Canvas()
  builder = @Builder(filename=uifile)

  btnOpenFile = G_.object(builder, "btnOpenFile")
  cbDomain = G_.object(builder, "cbDomain")
  
  choices = ["Abs", "Phase", "Real", "Imag"]
  for c in choices
    push!(cbDomain, c)
  end 
  setproperty!(cbDomain,:active,0)
  
  scSlice = G_.object(builder, "scSlice")
  adjSlice = @Adjustment(scSlice)
  setproperty!(adjSlice,:lower,1)
  setproperty!(adjSlice,:step_increment,1)    
  
  sbX = G_.object(builder, "sbX")
  adjX = @Adjustment(sbX)
  setproperty!(adjX,:lower,1)
  setproperty!(adjX,:upper,1024)
  setproperty!(adjX,:value,68)
  setproperty!(adjX,:step_increment,1)
  
  sbY = G_.object(builder, "sbY")
  adjY = @Adjustment(sbY)
  setproperty!(adjY,:lower,1)
  setproperty!(adjY,:upper,1024)
  setproperty!(adjY,:value,40)
  setproperty!(adjY,:step_increment,1)    
  
  signal_connect(btnOpenFile, "clicked") do widget
    dlg = @FileChooserDialog("Select file", @Null(), GtkFileChooserAction.OPEN, "gtk-open", GtkResponseType.OK)
    res = run(dlg)
    filename = ""
    if res == GtkResponseType.OK   
      filename = Gtk.bytestring(G_.filename(FileChooser(dlg)),true)
      if isfile(filename)
        loadData(filename)
      end
    end
    destroy(dlg)    
  end  
  
  NX = 1
  NY = 1
  NZ = 1
  data = nothing
  function loadData(filename)
    println(filename)
    if isfile(filename)

      f = Rawfile(filename)      
      data = f[]

      NX = size(data,1)
      NY = size(data,2)
      NZ = size(data,3)
    

      setproperty!(adjSlice,:upper,size(data,3))
      updateImages( nothing )
    end   
  end  
  
  
  canvasInitialized = false
  function initCanvas()
    println("Init Canvas ...")  

    gridCanvas = G_.object(builder, "gridCanvas")
    gridCanvas[2,2] = c1

    canvasInitialized = true
    
    showall(gridCanvas)
  end
    
  plotting = false  
  function updateImages( widget )
    println("Updating Image ...")
    
    if plotting
      return
    end
    
    plotting = true
    
    if data != nothing
      if !canvasInitialized 
        initCanvas()
      end
    
      sl = int( getproperty(adjSlice, :value, Float64) )
      println(sl)
      sl = min(max(sl,1),NZ)
      
      #colormap("jet")
      colormap(reverse(Color.colormap("grays",256)))
      activeDomainText = bytestring( G_.active_text(cbDomain))
      if activeDomainText == "Abs"
        p1 = imagesc( abs( data[:,:,sl]' ) )
      elseif activeDomainText == "Real"
        p1 = imagesc( real( data[:,:,sl]' ) )
      elseif activeDomainText == "Imag"
        p1 = imagesc( imag( data[:,:,sl]' ) )
      else      
        p1 = imagesc( angle( data[:,:,sl]' ) )
      end
      
      display(c1,p1)     
    end
    
    plotting = false    
  end     

  signal_connect(updateImages, adjSlice, "value_changed")
  signal_connect(cbDomain, "changed") do w, other...
    updateImages( w )
  end
  
  win = G_.object(builder, "mainWindow")
  show(win)  
  
  view = ImageViewer(win.handle)  
  
  
  signal_connect(win,"destroy") do object, args...
   exit()
  end

  Gtk.gc_move_ref(view, win)
end

#ViewerWindow()
#if !isinteractive()
#  wait(Condition())
#end
