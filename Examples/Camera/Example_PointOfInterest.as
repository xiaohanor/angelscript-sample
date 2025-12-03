
// Point of Interest Functionality Example
// See PointOfInterestStatics.as for more information
namespace FExampleCamera
{

	// This is how you apply a normal point of interest
	void ExampleApplyPointOfInterest()
	{
		auto Player = Game::GetMio();

		// Focus target is the point we will be focusing on
		// There are 3 ways of setting up the focus target
		FHazePointOfInterestFocusTargetInfo Target;

		// #1; This will apply an actor to focus on
		Target.SetFocusToActor(Player.OtherPlayer);

		// #2; This will apply a component to focus on
		Target.SetFocusToComponent(Player.OtherPlayer.Mesh);

		// #2; This will apply a mesh component with a socket to focus on
		Target.SetFocusToMeshComponent(Player.OtherPlayer.Mesh, n"Head");

		// This contains all the possible settings for the poi
		FApplyPointOfInterestSettings Settings;
		Settings.Duration = 1;

		Player.ApplyPointOfInterest(ExampleInstigator, Target, Settings);
	}


	// This is how you apply a clamped point of interest
	void ExampleApplyClampedPointOfInterest()
	{
		auto Player = Game::GetMio();

		// This contains all the possible settings for the clamped poi
		FApplyClampPointOfInterestSettings Settings;
		Settings.Duration = 1;

		// This is the clamps that should be used
		FHazeCameraClampSettings PoiClamps;
		PoiClamps.ApplyClampsYaw(90, 90);
		PoiClamps.ApplyClampsPitch(45, 45);

		FHazePointOfInterestFocusTargetInfo FocusTarget;
		FocusTarget.SetFocusToActor(Player.OtherPlayer);
		Player.ApplyClampedPointOfInterest(ExampleInstigator, FocusTarget, Settings, PoiClamps);
	}


	// You can also apply point of interest deferred
	void ExampleApplyScriptPointOfInterest()
	{
		auto Player = Game::GetMio();
		
		// This will create the POI, but NOT apply it.
		auto POI = Player.CreatePointOfInterest();

		// This will created a clamped POI, but NOT apply it.
		auto POI_Clamped = Player.CreatePointOfInterestClamped();
		
		// Then you apply all the settings on the poi
		POI.FocusTarget.SetFocusToActor(Player.OtherPlayer);
		POI.Settings.Duration = 1;

		// Last, you apply the poi.
		// It will be applied to the player you created it on.
		POI.Apply(ExampleInstigator, 2);

		// You can also clear the poi.
		// No instigator is needed here.
		// If you clear it like this. It is guaranteed to go away.
		POI.Clear();


		// Clearing it on the player requires an instigator.
		Player.ClearPointOfInterestByInstigator(ExampleInstigator);
	}





	UObject GetExampleInstigator() property
	{
		return nullptr;
	}
}
