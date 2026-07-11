package router

import (
	"net/http"
	"net/http/httputil"
	"net/url"

	"github.com/gin-gonic/gin"
)

func proxy(target string) gin.HandlerFunc {
	return func(c *gin.Context) {
		remote, err := url.Parse(target)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "invalid target"})
			return
		}
		proxy := httputil.NewSingleHostReverseProxy(remote)
		proxy.ServeHTTP(c.Writer, c.Request)
	}
}

func RegisterProjectRoutes(r *gin.RouterGroup, target string) {
	r.Any("/worlds/*path", proxy(target+"/api/v1/worlds"))
	r.Any("/works/*path", proxy(target+"/api/v1/works"))
	r.Any("/volumes/*path", proxy(target+"/api/v1/volumes"))
	r.Any("/chapters/*path", proxy(target+"/api/v1/chapters"))
	r.Any("/scenes/*path", proxy(target+"/api/v1/scenes"))
	r.Any("/tree/*path", proxy(target+"/api/v1/tree"))
}

func RegisterDocumentRoutes(r *gin.RouterGroup, target string) {
	r.Any("/documents/*path", proxy(target+"/api/v1/documents"))
}

func RegisterAIServiceRoutes(r *gin.RouterGroup, target string) {
	r.Any("/ai/*path", proxy(target+"/api/v1/ai"))
}

func RegisterNovelEngineRoutes(r *gin.RouterGroup, target string) {
	r.Any("/novel/*path", proxy(target+"/api/v1/novel"))
}

func RegisterCanonRoutes(r *gin.RouterGroup, target string) {
	r.Any("/canon/*path", proxy(target+"/api/v1/canon"))
}

func RegisterQualityRoutes(r *gin.RouterGroup, target string) {
	r.Any("/review/*path", proxy(target+"/api/v1/review"))
}

func RegisterSettingsRoutes(r *gin.RouterGroup, target string) {
	r.Any("/settings/*path", proxy(target+"/api/v1/settings"))
}

func RegisterExportRoutes(r *gin.RouterGroup, target string) {
	r.Any("/export/*path", proxy(target+"/api/v1/export"))
}

func RegisterTimelineRoutes(r *gin.RouterGroup, target string) {
	r.Any("/timeline/*path", proxy(target+"/api/v1/timeline"))
}

func RegisterSearchRoutes(r *gin.RouterGroup, target string) {
	r.Any("/search/*path", proxy(target+"/api/v1/search"))
}

func RegisterSkillRoutes(r *gin.RouterGroup, target string) {
	r.Any("/skills/*path", proxy(target+"/api/v1/skills"))
}

func RegisterFactionRoutes(r *gin.RouterGroup, target string) {
	r.Any("/factions/*path", proxy(target+"/api/v1/factions"))
}