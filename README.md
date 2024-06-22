WeekendRaytracing
=================
Eonil, Hoon H.. 2024.

This is experimental implementation for a path tracer.
Based on a great book ["Ray Tracing in One Weekend"](https://raytracing.github.io/books/RayTracingInOneWeekend.html).


To do
-----
- Consider using Intel's OIDN for denoising.
    - https://www.openimagedenoise.org

Idea
----

See also
--------
- DDGI.
    - https://morgan3d.github.io/articles/2019-04-01-ddgi/overview.html
    - Almost 1st gen. GI. Easy, cheap and clean.
    - Visibility check is the key.
        - Prevent shadow leak: Back-face hit culling, and ignore hitting with back-face.
        - Prevent light leak: Back-face hit culling.

- Nvidia Quake 2 RTX
    - Pure path ray tracing based rendering.
    - Direct + indirect + specular + denoiser.  
    - [Steam download](https://www.nvidia.com/en-us/geforce/news/quake-ii-rtx-ray-tracing-vulkan-vkray-geforce-rtx/#:~:text=Running%20on%20a%20Vulkan%20renderer,traditional%20effects%20or%20techniques%20utilized.)
    - [Keynote](https://www.youtube.com/watch?v=FewqoJjHR0A)

- Manifold Exploration (for offline rendering)
    - YouTube short introduction ([link](https://youtu.be/NRmkr50mkEE?si=CK90Up4MNqSpAPSn&t=196)))
    - Paper & Video ([link](https://www.cs.cornell.edu/projects/manifolds-sg12/)))

- Raytracing in Hybrid Real-Time Rendering (EA)
    - http://h3.gd/raytracing-in-hybrid-real-time-rendering/

- "ReSTIR". The latest GI technology. 
    - Spatial & temporal sample re-using.
    - For motion blur, we also can re-use the samples over sub-frames.
    - They are very likely re-used.
    - Bleeding edge is "Area ReSTIR". (2024)
    - If "ReSTIR" can be expanded to "area light", it also can be expanded to motion blur. Which just samples over time.  


- "Octahedral Encoding".
    - https://www.readkong.com/page/fullscreen/octahedron-environment-maps-6054207
