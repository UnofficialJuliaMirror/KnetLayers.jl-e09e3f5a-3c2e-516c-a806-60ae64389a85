struct Embed <: Model
    w
end
Embed(input::Int,embed::Int;winit=xavier) = Embed(Prm(winit(embed,input)))
(m::Embed)(x::Array{T}) where T<:Integer = m.w[:,x]
function (m::Embed)(x)
    if ndims(x) > 2
        y =  m.w * reshape(x,size(x,1),prod(size(x)[2:end]))
        return reshape(y,size(y,1),size(x)[2:end]...)
    else
        return m.w * x
    end
end

struct Linear <: Model
    w
    b
end
Linear(i::Int,o::Int;winit=xavier,binit=zeros)=Linear(Prm(winit(o,i)),Prm(binit(o)))
(m::Linear)(x) = (m.w * x .+ m.b)

struct Dense <: Model
    w
    b
    f
end
Dense(i::Int,o::Int;f=ReLU(),winit=xavier,binit=zeros)=Dense(Prm(winit(o,i)),Prm(binit(o)),f)
(m::Dense)(x) = m.f((m.w * x .+ m.b))

struct Conv <: Model
    w
    b
    stride
    padding
    mode
end
Conv(h::Int;winit=xavier,binit=zeros,opts...)=Conv(Prm(winit(h,1,1,1)),binit(1,1,1,1);opts...)
Conv(h::Int,w::Int;winit=xavier,binit=zeros,opts...)=Conv(Prm(winit(h,w,1,1)),binit(1,1,1,1);opts...)
Conv(h::Int,w::Int,c::Int;winit=xavier,binit=zeros,opts...)=Conv(Prm(winit(h,w,c,1)),binit(1,1,1,1);opts...)
Conv(h::Int,w::Int,c::Int,o::Int;winit=xavier,binit=zeros,opts...)=Conv(Prm(winit(h,w,c,o)),binit(1,1,o,1);opts...)
Conv(w,b;stride=1,padding=1,mode=1) = Conv(w,b,stride,padding,mode)
function (m::Conv)(x)
     n = ndims(x)
     if n == 4
         return conv4(m.w,x;stride=m.stride,padding=m.padding,mode=m.mode) .+ m.b
     elseif n == 3
         y = conv4(m.w,reshape(x,size(x)...,1);stride=m.stride,padding=m.padding,mode=m.mode) .+ m.b
     elseif n == 2
         y = conv4(m.w,reshape(x,size(x)...,1,1);stride=m.stride,padding=m.padding,mode=m.mode) .+ m.b
     elseif n == 1
         y = conv4(m.w,reshape(x,size(x)...,1,1,1);stride=m.stride,padding=m.padding,mode=m.mode) .+ m.b
     else
         error("Conv supports 1,2,3,4 D arrays only")
     end
     return reshape(y,size(y)[1:n])
end

struct BatchNorm <: Model
    params
    moments::Knet.BNMoments
end
BatchNorm(channels::Int;o...) =BatchNorm(Prm(bnparams(eltype(atype),channels)),bnmoments(;o...))
(m::BatchNorm)(x;o...) = batchnorm(x,m.moments,m.params;o...)
