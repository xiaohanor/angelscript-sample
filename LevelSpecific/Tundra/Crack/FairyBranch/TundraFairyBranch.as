class ATundraFairyBranch : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent Rotator;

	UPROPERTY(DefaultComponent, Attach = Rotator)
	UStaticMeshComponent BranchMesh;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactCallbackComp;

	TPerPlayer<UTundraPlayerShapeshiftingComponent> PlayersOnBranch;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"OnPlayerEnter");
		ImpactCallbackComp.OnGroundImpactedByPlayerEnded.AddUFunction(this, n"OnPlayerLeft");
	}

	UFUNCTION()
	private void OnPlayerLeft(AHazePlayerCharacter Player)
	{
		PlayersOnBranch[Player] = nullptr;
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		PlayersOnBranch[Player] = UTundraPlayerShapeshiftingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for(auto Player : PlayersOnBranch)
		{
			if(Player == nullptr)
				continue;

			float ForceToUse = 0;

			ETundraShapeshiftShape ShapeType = Player.GetCurrentShapeType();

			if(ShapeType == ETundraShapeshiftShape::Small)
			{
				if(Player.Player.IsMio())
					ForceToUse = 300;
			}
			else if(ShapeType == ETundraShapeshiftShape::Player)
				ForceToUse = 2000;
			else if(ShapeType == ETundraShapeshiftShape::Big)
				ForceToUse = 5000;

			Rotator.ApplyForce(Player.Owner.ActorLocation, FVector::DownVector * ForceToUse);
		}
	}
};