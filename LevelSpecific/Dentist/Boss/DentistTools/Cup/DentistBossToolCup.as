asset DentistBossToolCupGravitySettings of UMovementGravitySettings
{
	GravityAmount = 4000.0;
}

enum EDentistBossToolCupSortType
{
	None,
	Left,
	Right,
	Sides,
	MAX,
}

class ADentistBossToolCup : ADentistBossTool
{
	UPROPERTY(DefaultComponent)
	USceneComponent MeshOffsetRoot;

	UPROPERTY(DefaultComponent, Attach = MeshOffsetRoot)
	USceneComponent MeshScaleRoot;

	UPROPERTY(DefaultComponent, Attach = MeshScaleRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilityClasses.Add(UDentistBossToolCupRestrainPlayerCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UDentistBossToolCupMovementCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UDentistBossToolCupFlattenWithPlayerCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UDentistBossToolCupMoveToTargetCapability);
	default CapabilityComp.bCanBeDisabled = false;
	
	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	USphereComponent SphereCollisionComp;

	UPROPERTY(DefaultComponent)
	UDentistToothMovementResponseComponent ResponseComp;
	default ResponseComp.OnDashImpact = EDentistToothDashImpactResponse::Backflip;

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformTemporalLogComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;
	default ListedActorComp.bDelistWhileActorDisabled = false;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedActorPositionComp;
	default SyncedActorPositionComp.SyncRate = EHazeCrumbSyncRate::High;

	TOptional<AHazePlayerCharacter> RestrainedPlayer;
	TOptional<AHazePlayerCharacter> FlattenedPlayer;
	ADentistBossCupManager CupManager;

	FVector AngularVelocity;
	FRotator MeshCompInitialRotation;

	bool bHasBeenOpened = false;
	bool bIsFlattened = false;

	const float DashedIntoHorizontalImpulseSize = 3000.0;
	const float DashedIntoVerticalImpulseSize = 2000.0;
	const float DashedIntoAngularImpulseSize = 250.0;

	float TimeLastReset = -MAX_flt;

	UDentistBossSettings Settings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		ApplyDefaultSettings(DentistBossToolCupGravitySettings);
		ResponseComp.OnDashedInto.AddUFunction(this, n"OnDashedInto");
		MoveComp.AddMovementIgnoresActor(this, Dentist);
		MeshCompInitialRotation = MeshComp.RelativeRotation;

		AddActorDisable(Dentist);

		CupManager = TListedActors<ADentistBossCupManager>().GetSingle();

		Settings = UDentistBossSettings::GetSettings(Dentist);

		DentistBossDevToggles::CupPrinting.MakeVisible();
		SetActorControlSide(Game::Zoe);
	}

	UFUNCTION()
	private void OnDashedInto(AHazePlayerCharacter DashPlayer, FVector Impulse, FHitResult Impact)
	{
		if(!DashPlayer.HasControl())
			return;

		if(CupManager.ChosenCup.IsSet())
			return;

		if(bHasBeenOpened)
			return;

		if(!CupManager.bCupSortingFinished)
			return;

		CrumbDashedInto(Impulse);
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbDashedInto(FVector DashImpulse)
	{
		FVector FlatImpulseDir = DashImpulse.GetSafeNormal().ConstrainToPlane(FVector::UpVector);
		FlingAway(FlatImpulseDir);

		// Clear Dash into cup tutorial prompt
		CupManager.PlayerInCup.OtherPlayer.RemoveTutorialPromptByInstigator(CupManager);
		CupManager.ChosenCup.Set(this);

		FDentistBossEffectHandlerOnCupChosenByDashingPlayerParams EventParams;
		EventParams.DashingPlayer = CupManager.PlayerInCup.OtherPlayer;
		EventParams.Cup = this;
		EventParams.bPlayerIsInCup = this.RestrainedPlayer.IsSet();
		UDentistBossEffectHandler::Trigger_OnCupChosenByDashingPlayer(Dentist, EventParams);
	}

	void FlingAway(FVector Direction)
	{
		FVector CupImpulse = Direction * DashedIntoHorizontalImpulseSize;
		CupImpulse += FVector::UpVector * DashedIntoVerticalImpulseSize;

		AddMovementImpulse(CupImpulse);
		AngularVelocity += Direction.CrossProduct(FVector::UpVector) * DashedIntoAngularImpulseSize;
		bHasBeenOpened = true;
	}

	void BecomeFlattened()
	{
		FDentistBossEffectHandlerOnCupBecomeFlattenedParams EffectParams;
		EffectParams.Cup = this;
		EffectParams.bPlayerIsInCup = RestrainedPlayer.IsSet();
		UDentistBossEffectHandler::Trigger_OnCupBecomeFlattenedParams(Dentist, EffectParams);

		if(RestrainedPlayer.IsSet())
		{
			FlattenedPlayer.Set(RestrainedPlayer.Value);
		}
		
		Timer::SetTimer(this, n"DisappearAfterFlattened", Settings.CupDisappearDelayAfterFlattened);
	}

	UFUNCTION()
	void DisappearAfterFlattened()
	{
		FDentistBossEffectHandlerOnCupDisappearAfterBecomingFlattenedParams EffectParams;
		EffectParams.Cup = this;
		EffectParams.bPlayerIsInCup = RestrainedPlayer.IsSet();
		UDentistBossEffectHandler::Trigger_OnCupDisappearAfterBecomingFlattenedParams(Dentist, EffectParams);

		if(RestrainedPlayer.IsSet())
		{
			RestrainedPlayer.Reset();
			AddActorVisualsBlock(Dentist);
		}
		else
		{
			Deactivate();
		}
	}

	void Activate() override
	{
		Super::Activate();
		
		RemoveActorDisable(Dentist);
	}

	void Deactivate() override
	{
		Super::Deactivate();
		
		AddActorDisable(Dentist);
	}

	void Reset() override
	{
		Super::Reset();
		
		RestrainedPlayer.Reset();

		MeshComp.RelativeRotation = MeshCompInitialRotation;
		AngularVelocity = FVector::ZeroVector;	
		ActorVelocity = FVector::ZeroVector;

		bHasBeenOpened = false;

		MeshScaleRoot.SetWorldScale3D(FVector::OneVector);

		CupManager.ChosenCup.Reset();
		CupManager.PlayerInCup = nullptr;

		RemoveActorVisualsBlock(Dentist);

		TimeLastReset = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TEMPORAL_LOG(this)
			.Value("Cake Relative Location", ActorLocation - Dentist.Cake.ActorLocation)
			.Sphere("Location", ActorLocation, 50, FLinearColor::Red, 10)
			.Value("Type", ToolType)
			.Value("Relative Location", ActorRelativeLocation)
			.Value("Relative Rotation", ActorRelativeRotation)
			.Value("Is Flattened", bIsFlattened)
		;

		if (DentistBossDevToggles::CupPrinting.IsEnabled())
		{
			if (RestrainedPlayer.IsSet())
			{
				Debug::DrawDebugString(ActorLocation, "here", ColorDebug::Ruby);
			}
			Debug::DrawDebugString(ActorLocation, "\n\n" + ActorNameOrLabel, ColorDebug::Cerulean);

			switch (ToolType)
			{
				case EDentistBossTool::CupLeft:
					Debug::DrawDebugString(ActorLocation, "\n\n\n\n" + GetSaneName(ToolType), ColorDebug::Blue);
				break;
				case EDentistBossTool::CupMiddle:
					Debug::DrawDebugString(ActorLocation, "\n\n\n\n" + GetSaneName(ToolType), ColorDebug::Yellow);
				break;
				case EDentistBossTool::CupRight:
					Debug::DrawDebugString(ActorLocation, "\n\n\n\n" + GetSaneName(ToolType), ColorDebug::Ruby);
				break;
				default:
				break;
			}
		}
	}

	private FString GetSaneName(EDentistBossTool Enum) const
	{
		FString Unused;
		FString Used;
		FString EnumString = "" + Enum;
		FString Splitter = ":";
		String::Split(EnumString, Splitter, Unused, Used, ESearchCase::IgnoreCase, ESearchDir::FromEnd);
		return Used;
	}

	FVector GetTargetLocation() const
	{
		FVector TargetLocation;
		if(ToolType == EDentistBossTool::CupLeft)
			TargetLocation = Dentist.Cake.ActorLocation + DentistBossMeasurements::LeftCupCakeRelativeLocation;
		else if(ToolType == EDentistBossTool::CupMiddle)
			TargetLocation = Dentist.Cake.ActorLocation + DentistBossMeasurements::MiddleCupCakeRelativeLocation;
		else
			TargetLocation = Dentist.Cake.ActorLocation + DentistBossMeasurements::RightCupCakeRelativeLocation;
		return TargetLocation;
	}

	FRotator GetTargetRotation() const
	{
		FRotator TargetRotation;
		TargetRotation = FRotator::MakeFromXZ(-FVector::UpVector, ActorUpVector);
		return TargetRotation;
	}

	void PutCupAtTarget()
	{
		ActorLocation = GetTargetLocation();
		ActorRotation = GetTargetRotation();
	}
};