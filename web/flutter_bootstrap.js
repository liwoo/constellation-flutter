{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    try {
      updateSplashStatus("Preparing the game engine…");
      const appRunner = await engineInitializer.initializeEngine();

      updateSplashStatus("Lighting up the constellation…");
      await appRunner.runApp();
    } catch (error) {
      console.error("Constellation failed to start", error);
      showSplashError();
    }
  }
});
