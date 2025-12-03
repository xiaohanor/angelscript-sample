UCLASS(Abstract)
class ARedSpaceSeeSaw : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UFauxPhysicsAxisRotateComponent SeeSawRoot;

	UPROPERTY(DefaultComponent, Attach = SeeSawRoot)
	USceneComponent LeftPlatformRoot;

	UPROPERTY(DefaultComponent, Attach = LeftPlatformRoot)
	UStaticMeshComponent LeftPlatformMesh;

	UPROPERTY(DefaultComponent, Attach = SeeSawRoot)
	USceneComponent RightPlatformRoot;

	UPROPERTY(DefaultComponent, Attach = RightPlatformRoot)
	UStaticMeshComponent RightPlatformMesh;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComp;

	TArray<AHazePlayerCharacter> LeftPlatformPlayers;
	TArray<AHazePlayerCharacter> RightPlatformPlayers;

	float ForcePerPlayers = 6.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovementImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"PlayerLanded");
		MovementImpactCallbackComp.OnGroundImpactedByPlayerEnded.AddUFunction(this, n"PlayerLeft");

		TArray<USceneComponent> PlatformRoots;
		PlatformRoots.Add(LeftPlatformRoot);
		PlatformRoots.Add(RightPlatformRoot);

		for (USceneComponent PerchRoot : PlatformRoots)
		{
			FRotator OriginalRotation = PerchRoot.WorldRotation;
			PerchRoot.SetAbsolute(false, true, false);
			PerchRoot.SetWorldRotation(OriginalRotation);
		}
	}

	UFUNCTION()
	private void PlayerLanded(AHazePlayerCharacter Player)
	{
		UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Player);
		float Force = 0.0;
		if (MoveComp.GroundContact.Component == LeftPlatformMesh)
		{
			Force = 2.0;
			LeftPlatformPlayers.Add(Player);
		}
		else if (MoveComp.GroundContact.Component == RightPlatformMesh)
		{
			Force = -2.0;
			RightPlatformPlayers.Add(Player);
		}

		SeeSawRoot.ApplyAngularImpulse(Force);
	}

	UFUNCTION()
	private void PlayerLeft(AHazePlayerCharacter Player)
	{
		UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Player);
		if (MoveComp.PreviousGroundContact.Component == LeftPlatformMesh)
			LeftPlatformPlayers.Remove(Player);
		else if (MoveComp.PreviousGroundContact.Component == RightPlatformMesh)
			RightPlatformPlayers.Remove(Player);
			
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float Force = LeftPlatformPlayers.Num() * ForcePerPlayers;
		Force += RightPlatformPlayers.Num() * -ForcePerPlayers;

		SeeSawRoot.ApplyAngularForce(Force);
	}
}