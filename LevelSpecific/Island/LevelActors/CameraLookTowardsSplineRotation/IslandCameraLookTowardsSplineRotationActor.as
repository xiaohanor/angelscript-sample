UCLASS(NotBlueprintable)
class AIslandCameraLookTowardsSplineRotationActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;
	default RequestComp.InitialStoppedPlayerCapabilities.Add(n"IslandCameraLookTowardsSplineRotationCapability");

	#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent EditorIcon;
	default EditorIcon.SpriteName = "S_Emitter";
	default EditorIcon.RelativeScale3D = FVector(2);
	#endif

	UPROPERTY(EditInstanceOnly)
	ASplineActor SplineToLookTowards;

	UFUNCTION(BlueprintCallable)
	void StartCameraLookTowardsSplineRotationForPlayer(AHazePlayerCharacter Player)
	{
		if(SplineToLookTowards == nullptr)
		{
			PrintError(f"Trying to call StartCameraLookTowardsSplineRotationForPlayer on {this}, but SplineToLookTowards is nullptr!");
			return;
		}

		auto Component = UIslandCameraLookTowardsSplineRotationComponent::GetOrCreate(Player);
		if(Component.HasSplineToFollow())
		{
			PrintError(f"Trying to call StartCameraLookTowardsSplineRotationForPlayer on {this}, but the player is already looking towards a spline!");
			return;
		}

		Component.Spline = SplineToLookTowards.Spline;

		RequestComp.StartInitialSheetsAndCapabilities(Player, this);
	}

	UFUNCTION(BlueprintCallable)
	void StopCameraLookTowardsSplineRotationForPlayer(AHazePlayerCharacter Player)
	{
		auto Component = UIslandCameraLookTowardsSplineRotationComponent::GetOrCreate(Player);
		if(!Component.HasSplineToFollow())
			return;

		RequestComp.StopInitialSheetsAndCapabilities(Player, this);
	}
};