event void FOnArtifactPickUp(AHazePlayerCharacter Player);

class ASanctuaryWeeperArtifact : AHazeActor
{
	FOnArtifactPickUp OnArtifactPickUp;
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRoot;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UAnimSequence CarryAnim;

	UPROPERTY(DefaultComponent)
	USceneComponent LightConeSource;

	UPROPERTY(DefaultComponent, Attach = LightConeSource)
	USpotLightComponent SpotLight;

	float LightConeAngle = 25;
	float LightConeRange = 1500;


	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractComp;
	default InteractComp.UsableByPlayers = EHazeSelectPlayer::Both;

	AHazePlayerCharacter PlayerCharacter;

	USanctuaryWeeperArtifactUserComponent UserComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractComp.OnInteractionStarted.AddUFunction(this, n"OnPickUp");
		for (auto Player : Game::Players)
		{
			UserComp = USanctuaryWeeperArtifactUserComponent::GetOrCreate(Player);
		}

	}
	
	UFUNCTION(BlueprintCallable)
	void EquipArtifact(AHazePlayerCharacter Player)
	{
		OnArtifactPickUp.Broadcast(Player);
		USanctuaryWeeperArtifactUserComponent::Get(Player).Artifact = this;
		this.PlayerCharacter = Player;

		AttachToActor(Player);
		InteractComp.Disable(this);
	}


	UFUNCTION()
	private void OnPickUp(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player)
	{
		EquipArtifact(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for(auto ResponseComp : UserComp.ArtifactResponseComps)
		{
			if(IsInLight(ResponseComp.WorldLocation))
			{
				ResponseComp.AddAffector(this);
			}
			else
			{
				ResponseComp.RemoveAffector(this);
			}
			

		}
	}


	bool IsInLight(FVector TargetLocation)
	{
		FVector ToTarget = TargetLocation - ActorLocation;

		if(ToTarget.Size() > LightConeRange)
			return false;
		if(ToTarget.GetAngleDegreesTo(ActorForwardVector) > LightConeAngle)
			return false;
		if(!HasLineOfSight(TargetLocation))
			return false;

		return true;
	}


	bool HasLineOfSight(FVector TargetLocation)
	{
		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::WorldGeometry);
		TraceSettings.IgnorePlayers();
		TraceSettings.IgnoreActor(this);

		auto HitResult = TraceSettings.QueryTraceSingle(LightConeSource.WorldLocation, TargetLocation);

		if(HitResult.bBlockingHit)
		{
			// Debug::DrawDebugLine(HitResult.TraceStart, HitResult.ImpactPoint, FLinearColor::Red, 5, 0);
			return false;
		}

		return true;
	}

};