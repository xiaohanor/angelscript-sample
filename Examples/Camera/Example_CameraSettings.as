// Camera Settings Functionality Example
namespace FExampleCamera
{

	// Basic examples of how to apply camera settings
	void ExampleApplyCameraSettings()
	{	
		// First, get the camera settings from the player
		auto CameraSettings = UCameraSettings::GetSettings(Game::Mio);

		// The you apply the wanted value, with a blend type and a instigator
		CameraSettings.FOV.Apply(70, ExampleInstigator, 2, EHazeCameraPriority::Medium);

		// The camera settings contains information for both camera and spring arm
		CameraSettings.PivotOffset.Apply(FVector::ZeroVector, ExampleInstigator, 2, EHazeCameraPriority::Medium);

		// You can also apply clamps
		CameraSettings.Clamps.Apply(FHazeCameraClampSettings(90, 45), ExampleInstigator, 2, EHazeCameraPriority::Medium);

		// And you can also apply camera settings asset
		Game::Mio.ApplyCameraSettings(ExampleCameraDataAsset, 2, ExampleInstigator, EHazeCameraPriority::Medium);

		// You can customize the priority of the camera setting a lot
		// If you have multiple priority you can also add a sub priority to keep them separated.
		// Camera settings are added as mutually exclusive by default. This means that every setting has to have a unique priority.
		// If you don't want this, you can turn off bIsMutuallyExclusive. Then the last added camera setting will have the highest priority
		CameraSettings.FOV.Apply(70, ExampleInstigator, 2, EHazeCameraPriority::Medium, 100);
	}


	// Basic examples of how to clear camera settings
	void ExampleClearCameraSettings()
	{
		// First, get the camera settings from the player
		auto CameraSettings = UCameraSettings::GetSettings(Game::Mio);

		// You can clear the settings individually
		CameraSettings.FOV.Clear(ExampleInstigator);

		// Or just clear all of them
		Game::Mio.ClearCameraSettingsByInstigator(ExampleInstigator);
	}


	// External camera settings types
	void ExampleHandleExternalCameraSetting()
	{
		// You can always place a camera settings volume in the level.
		// This contains all the possible settings and will activate when the player enters the volume
		AHazeCameraVolume CameraSettingsVolume;

		// You can also place a camera settings actor in the level.
		// This one also has all the potential camera settings
		// But this one you have to apply and clear manually.
		// Whit this, you can control camera settings when having gameplay in the level script
		AHazeCameraSettingsActor CameraSettingsActor;
		CameraSettingsActor.Apply(Game::Mio);
		CameraSettingsActor.Clear(Game::Mio);
	}




	UHazeCameraSettingsDataAsset GetExampleCameraDataAsset() property
	{
		return nullptr;
	}
}