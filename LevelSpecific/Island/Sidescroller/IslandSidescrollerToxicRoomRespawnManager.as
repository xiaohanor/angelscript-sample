class AIslandSidescrollerToxicRoomRespawnManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent BillboardComp;
#endif

	UPROPERTY(DefaultComponent)
	UHazeMovablePlayerTriggerComponent PlayerTriggerComp;
	default PlayerTriggerComp.ShapeColor = FLinearColor::Green;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

	UPROPERTY(EditAnywhere, Category = "Setup")
	ARespawnPoint RespawnPoint;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TArray<AActor> Platforms;

	UPROPERTY(EditAnywhere, Category = "Setup")
	ADeathVolume DeathVolume;

	TArray<AActor> PlatformsLandedOn;

	TPerPlayer<UPlayerMovementComponent> MoveComps;
	FVector RespawnOriginalLocation;

	float DeathHeight;

	default ActorTickEnabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RespawnOriginalLocation = RespawnPoint.ActorLocation;

		PlayerTriggerComp.OnPlayerEnter.AddUFunction(this, n"FollowPlayer");
		PlayerTriggerComp.OnPlayerLeave.AddUFunction(this, n"StopFollowing");

		for(auto Player : Game::Players)
		{
			MoveComps[Player] = UPlayerMovementComponent::Get(Player);
		}

		DeathHeight = DeathVolume.ActorLocation.Z + DeathVolume.Bounds.BoxExtent.Z;
	}

	UFUNCTION(NotBlueprintCallable)
	private void FollowPlayer(AHazePlayerCharacter Player)
	{
		SetActorTickEnabled(true);
	}

	UFUNCTION(NotBlueprintCallable)
	private void StopFollowing(AHazePlayerCharacter Player)
	{
		RespawnPoint.ActorLocation = RespawnOriginalLocation;
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CheckForNewLandedPlatforms();
		
		TOptional<FVector> SafeMostRightLocationOnPlatformLandedOn;
		for(auto Platform : PlatformsLandedOn)
		{
			FVector Origin;
			FVector BoxExtent;
			Platform.GetActorBounds(true, Origin, BoxExtent);

			FVector TopOfPlatform = Origin + FVector::UpVector * BoxExtent.Z;
			if(TopOfPlatform.Z < DeathHeight)
				continue;

			if(SafeMostRightLocationOnPlatformLandedOn.IsSet())
			{
				if(SafeMostRightLocationOnPlatformLandedOn.Value.X > TopOfPlatform.Z)
					continue;
			}

			SafeMostRightLocationOnPlatformLandedOn.Set(TopOfPlatform);
		}

		if(SafeMostRightLocationOnPlatformLandedOn.IsSet())
			RespawnPoint.ActorLocation = SafeMostRightLocationOnPlatformLandedOn.Value;
		else
			RespawnPoint.ActorLocation = RespawnOriginalLocation;
	}

	private void CheckForNewLandedPlatforms()
	{
		for(auto MoveComp : MoveComps)
		{
			if(!MoveComp.IsOnAnyGround())
				continue;

			AActor GroundImpact = MoveComp.GroundContact.Actor;

			if(!Platforms.Contains(GroundImpact))
				continue;

			if(PlatformsLandedOn.Contains(GroundImpact))
				continue;

			PlatformsLandedOn.AddUnique(GroundImpact);
		}
	}
};
