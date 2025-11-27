Este proyecto implementa un pipeline CI/CD completo para la aplicación KubeFoods Backend, automatizando el proceso de construcción, despliegue, validación y rollback en un clúster Kubernetes.

La arquitectura del pipeline sería el siguiente:

Git Push → Build Docker Image → Push to Registry → Deploy to Kubernetes → Validate → Rollback (si falla)

La estructura del proyecto tiene un aspecto como este:

kubefoods-cicd/
├── .github/workflows/
│   └── pipeline.yml          # Pipeline CI/CD
├── scripts/
│   └── validate.sh           # Script de validación y rollback
├── deployment.yaml           # Manifiesto Kubernetes Deployment
├── service.yaml             # Manifiesto Kubernetes Service
├── Dockerfile               # Definición de la imagen Docker
├── index.html               # Página principal
├── health.html              # Endpoint de health check
└── README.md               # Esta documentación



El pipeline implementa un mecanismo de auto-recuperación mediante health checks post-despliegue que monitoriza el estado de los pods y la disponibilidad del servicio; cuando detecta estados críticos como ImagePullBackOff, CrashLoopBackOff o timeout en los endpoints, ejecuta automáticamente un rollout undo para revertir a la revisión estable anterior, asegurando zero-downtime y manteniendo el SLA durante actualizaciones problemáticas.


El proyecto me tomó mucho tiempo por lo que no hice fotos al final. Sin embargo, el proceso se puede ir viendo en las versiones del repositorio.

Alguna reflexión puede ser que si que hay una curva de aprendizaje notable a la hora de utilizar estos programas.