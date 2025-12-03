class ASkylineConstrainPlayerStartLocations : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBoxComponent VisualizerBox;
	default VisualizerBox.WorldScale3D = FVector(4.0, 0.01, 4.0);
	default VisualizerBox.bHiddenInGame = true;
	default VisualizerBox.bCanEverAffectNavigation = false;
	default VisualizerBox.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent)
	UTextRenderComponent Text;
	default Text.Text = FText::FromString("Constrain player start \nlocations to this plane.");
	default Text.RelativeLocation = FVector(-120.0, 0.0, 60.0);
	default Text.RelativeRotation = FRotator(0.0, 90.0, 0.0);
	default Text.bHiddenInGame = true;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			// If used for real, this should take respawn points into account
			// For now, just constrain to our XZ-plane
			FVector PlaneLoc = Player.ActorLocation.ConstrainToPlane(ActorRightVector);
			PlaneLoc.Y = ActorLocation.Y;
			Player.TeleportActor(PlaneLoc, Player.ActorRotation, this);
			Player.SnapCameraAtEndOfFrame(FRotator(-15.0, 0.0, 0.0), EHazeCameraSnapType::BehindUser);			
		}
	}
};