UCLASS(Abstract)
class ASketchbookLevelScriptActor : AHazeLevelScriptActor
{
	UFUNCTION(BlueprintCallable)
	void HostActivateFullscreenCamera(AHazeCameraActor Camera, float BlendTime = 2.0)
	{
		if(!Network::HasWorldControl())
			return;

		// We are host, crumb activation to both players
		Crumb_ActivateCamera(Camera, BlendTime);
	}

	UFUNCTION(CrumbFunction)
	private void Crumb_ActivateCamera(AHazeCameraActor Camera, float BlendTime)
	{
		Game::Zoe.ActivateCamera(Camera, BlendTime, this, EHazeCameraPriority::High);
	}

	UFUNCTION(BlueprintCallable)
	void HostDeactivateFullscreenCamera(AHazeCameraActor Camera, float BlendOutTime = -1.0)
	{
		if(!Network::HasWorldControl())
			return;

		// We are host, crumb deactivation to both players
		Crumb_DeactivateCamera(Camera, BlendOutTime);
	}

	UFUNCTION(CrumbFunction)
	private void Crumb_DeactivateCamera(AHazeCameraActor Camera, float BlendOutTime = -1.0)
	{
		Game::Zoe.DeactivateCamera(Camera, BlendOutTime);
	}

	UFUNCTION(BlueprintCallable)
	void HostDeactivateFullscreenCameraByInstigator(float BlendOutTime = -1.0)
	{
		if(!Network::HasWorldControl())
			return;

		// We are host, crumb deactivation to both players
		Crumb_DeactivateCameraByInstigator(BlendOutTime);
	}

	UFUNCTION(CrumbFunction)
	private void Crumb_DeactivateCameraByInstigator(float BlendOutTime = -1.0)
	{
		Game::Zoe.DeactivateCameraByInstigator(this, BlendOutTime);
	}
};