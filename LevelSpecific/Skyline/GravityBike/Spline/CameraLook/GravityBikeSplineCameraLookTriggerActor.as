UCLASS(NotBlueprintable)
class AGravityBikeSplineCameraLookTriggerActor : APlayerTrigger
{
	default bTriggerForZoe = false;
	default bTriggerLocally = false;

	UPROPERTY(EditInstanceOnly)
	AGravityBikeSplineCameraLookSplineActor CameraLookSplineActor;

	UPROPERTY(EditInstanceOnly)
	EInstigatePriority Priority = EInstigatePriority::Low;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		if(CameraLookSplineActor == nullptr)
		{
			PrintError(f"{this} has no CameraLookSplineActor assigned!");
			return;
		}
		
		OnPlayerEnter.AddUFunction(this, n"OnEnter");
		OnPlayerLeave.AddUFunction(this, n"OnLeave");
	}

	UFUNCTION()
	private void OnEnter(AHazePlayerCharacter Player)
	{
		auto GravityBike = UGravityBikeSplineDriverComponent::Get(Player).GravityBike;
		if(GravityBike == nullptr)
			return;

		GravityBike.CameraLookSplineComps.Apply(CameraLookSplineActor.CameraLookSplineComp, this, Priority);
	}

	UFUNCTION()
	private void OnLeave(AHazePlayerCharacter Player)
	{
		auto GravityBike = UGravityBikeSplineDriverComponent::Get(Player).GravityBike;
		if(GravityBike == nullptr)
			return;

		GravityBike.CameraLookSplineComps.Clear(this);
	}
};