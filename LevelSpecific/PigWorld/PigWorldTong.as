UCLASS(Abstract)
class APigWorldTong : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UStaticMeshComponent BounceMeshComp;

	UPROPERTY(DefaultComponent, Attach = BounceMeshComp)
	UArrowComponent LaunchDirectionComp;

	UPROPERTY(DefaultComponent, Attach = BounceMeshComp)
	UBoxComponent OverlapComp;


	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactComp;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactComp.OnGroundImpactedByPlayer.AddUFunction(this, n"Impact");
	}

	UFUNCTION()
	private void Impact(AHazePlayerCharacter Player)
	{
		if(OverlapComp.IsOverlappingActor(Player))
			OnImpact(Player);
	}



	UFUNCTION(BlueprintEvent)
	void OnImpact(AHazePlayerCharacter Player){}
};
