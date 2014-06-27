using Gtk.ShortNames, Gtk.GConstants
using Winston

export viewer, ViewerWindow

type ViewerWindow <: Gtk.GtkWindow
  handle::Ptr{Gtk.GObject}
end

function ViewerWindow()

  #println( joinpath( dirname(Base.source_path()), "Viewer.ui" ) )

  c1 = @Canvas()
  #builder = Builder(filename=joinpath( dirname(Base.source_path()), "Viewer.ui" ))
  #builder = Builder(filename= "D:\\Users\\tknopp\\Dropbox\\julia\\MPI\\src\\Viewer.ui" )
  builder = @Builder(filename= "/Users/knopp/Dropbox/julia/MPI/src/Viewer.ui" )
  

  btnOpenFile = G_.object(builder, "btnOpenFile")
  #btnAbs = G_.object(builder, "btnAbs")
  
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

      NX = int( getproperty(adjX, :value, Float64) )
      NY = int( getproperty(adjY, :value, Float64) )
      NZ = int(filesize(filename) / sizeof(Complex128) / (NY * NX) )
    
      data = open(filename, "r") do fd
        read(fd, Complex128, (NX, NY, NZ) )
      end
      setproperty!(adjSlice,:upper,NZ)
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
      if sl < 1
        sl = 1
      end
      if sl > NZ
        sl = NZ
      end
             
      
      colormap("jet")
      #if getproperty(btnAbs,:active,Bool)
      #  p1 = imagesc( abs( data[:,:,sl]' ) )
      #else  
        p1 = imagesc( angle( data[:,:,sl]' ) )
      #end
      
      display(c1,p1)     
    end
    
    plotting = false    
  end     

  signal_connect(updateImages, adjSlice, "value_changed")
  
  win = G_.object(builder, "mainWindow")
  show(win)  
  
  view = ViewerWindow(win.handle)  
  
  
  signal_connect(win,"destroy") do object, args...
   exit()
  end

  Gtk.gc_move_ref(view, win)
end

#ViewerWindow()
#if !isinteractive()
#  wait(Condition())
#end
