UCLASS(Abstract)
class ADesertBreakPillarDouble : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UHazeSphereCollisionComponent CollisionComp;

	AHazePlayerCharacter FirstPlayer;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactComp;

	UPROPERTY(EditAnywhere)
	float FallDelay = 1.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactComp.OnGroundImpactedByPlayer.AddUFunction(this,n"ImpactStart");
		ImpactComp.OnGroundImpactedByPlayerEnded.AddUFunction(this,n"ImpactEnd");
	}

	UFUNCTION()
	private void ImpactEnd(AHazePlayerCharacter Player)
	{
		if(FirstPlayer == Player)
		{
			FirstPlayer = nullptr;
		}
	}

	UFUNCTION()
	private void ImpactStart(AHazePlayerCharacter Player)
	{
		if(FirstPlayer == nullptr)
		{
			FirstPlayer = Player;
		}
		else if(Player == FirstPlayer.GetOtherPlayer())
		{
			BreakPerchPoint();
		}
	}

	UFUNCTION(BlueprintEvent)
	void BreakPerchPoint()
	{
		//BP stuff :)
	}
};