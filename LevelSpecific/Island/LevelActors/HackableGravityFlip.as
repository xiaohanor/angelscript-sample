
UCLASS(Abstract)
class AHackableGravityFlip : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = true;
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent BillboardComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent PlatformMesh;	

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	FHazeAcceleratedVector StartVector;
	FHazeAcceleratedVector TargetVector;
	bool bActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay(){}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bActive)
		{
			StartVector.AccelerateTo(TargetVector.Value, 6.0, DeltaSeconds);

			Game::GetMio().OverrideGravityDirection(StartVector.Value.GetSafeNormal(), this, EInstigatePriority::Normal);
			Game::GetZoe().OverrideGravityDirection(StartVector.Value.GetSafeNormal(), this, EInstigatePriority::Normal);
		}
	}

	UFUNCTION()
	void ChangeGravity()
	{
		StartVector.Value = -Game::GetMio().GetActorUpVector();
		TargetVector.Value = -this.GetActorUpVector();

		TListedActors<AHackableGravityFlip> Actors;

		for (auto Actor : Actors)
		{
			if(Actor ==nullptr)
				return;

			Actor.ClearGravity();
		}

		Game::GetMio().OverrideGravityDirection(StartVector.Value, this, EInstigatePriority::Normal);
		Game::GetZoe().OverrideGravityDirection(StartVector.Value, this, EInstigatePriority::Normal);

		bActive = true;
	}
	UFUNCTION()
	void ClearGravity()
	{
		Game::GetMio().ClearGravityDirectionOverride(this);
		Game::GetZoe().ClearGravityDirectionOverride(this);
	}
}
