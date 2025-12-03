struct FSkylineInnerReceptionistPixelRow
{
	TArray<USkylineInnerReceptionistPixelComponent> PixelMeshes;
}

struct FSkylineInnerReceptionistPixelRowExpression
{
	TArray<bool> Lits;
}

asset SkylineInnerReceptionistSheet of UHazeCapabilitySheet
{
	Capabilities.Add(USkylineInnerReceptionistPixelFaceCapability);
	Capabilities.Add(USkylineInnerReceptionistFindInterestPointCapability);
	Capabilities.Add(USkylineInnerReceptionistMovementCapability);
	Capabilities.Add(USkylineInnerReceptionistLookAtCapability);
	Capabilities.Add(USkylineInnerReceptionistHitHeadCapability);
	Capabilities.Add(USkylineInnerReceptionistExterminateCapability);
	Capabilities.Add(USkylineInnerReceptionistHeadMoveCapability);

	Capabilities.Add(USkylineInnerReceptionistEventIdleCapability);
	Capabilities.Add(USkylineInnerReceptionistEventTickledCapability);
};

enum ESkylineInnerReceptionistBotState
{
	Working,
	Greetings,
	Friendly,
	Laughing,
	Afraid,
	Schocked,
	Bracing,
	WhatAREYouDOING,
	Annoyed,
	Hit1,
	Hit2,
	Dead,
	Rebooting,
	ExterminateMode,
	Smug,
}

enum ESkylineInnerReceptionistBotExpression
{
	Normal,
	Smile,
	Hello,
	Smirk,
	Sunglasses,
	uvu,
	xD,
	Cat,

	Worried,
	Bracing,
	Shocked,
	Annoyed,
	Afraid,
	Interrobang,

	Hit,
	AntWar,
	Dark,
	Reboot,
	Exterminate,
}

class ASkylineInnerReceptionistBot : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY(DefaultComponent, RootComponent)
	UCapsuleComponent Collision;

	UPROPERTY(DefaultComponent, Attach = Collision)
	USphereComponent TopSphere;

	UPROPERTY(DefaultComponent, Attach = Collision)
	UFauxPhysicsConeRotateComponent FauxRoot;

	UPROPERTY(DefaultComponent, Attach = FauxRoot)
	UStaticMeshComponent BodyMesh;

	UPROPERTY(DefaultComponent, Attach = FauxRoot)
	UStaticMeshComponent HeadMesh;

	UPROPERTY(DefaultComponent, Attach = HeadMesh)
	UStaticMeshComponent DisplayMesh;

	UPROPERTY(DefaultComponent, Attach = HeadMesh)
	USceneComponent PixelsAttachment;

	UPROPERTY(DefaultComponent, Attach = HeadMesh)
	UNiagaraComponent SmokeVFX;

	UPROPERTY(DefaultComponent, Attach = HeadMesh)
	UNiagaraComponent ElectricTicklingVFX;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;
	default CapabilityComponent.DefaultSheets.Add(SkylineInnerReceptionistSheet);

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ExpressionQueue;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedVectorComponent SyncedHeadLookDirection;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncPositionComp;

	UPROPERTY(EditAnywhere)
	UStaticMesh PixelMesh;

	UPROPERTY(EditAnywhere)
	UMaterialInstance PixelDarkMaterial;

	UPROPERTY(EditAnywhere)
	UMaterialInstance PixelMaterial;

	UPROPERTY(EditAnywhere)
	UMaterialInstance RedPixelMaterial;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem KillElectricVFX;

	UPROPERTY(EditAnywhere)
	ASkylineInnerReceptionistArea GreetingsVolume = nullptr; 

	UPROPERTY(EditAnywhere)
	ASkylineInnerReceptionistArea AnnoyedVolume = nullptr; 

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent BladeResponseComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipTargetComponent WhipTargetComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent WhipResponseComp;

	UPROPERTY(EditInstanceOnly)
	ASkylineInnerCoffeeCup CoffeeCup = nullptr;

	TArray<FSkylineInnerReceptionistPixelRow> PixelRows;
	TArray<FSkylineInnerReceptionistPixelRowExpression> CachedLitLamps;
	bool bLocalHasSetDark = false;
	bool bLocalHasSetAntWar = false;

	bool bMoved = false;
	float Gravity = -980.0 * 2.0;
	FVector PendingImpulse;

	ESkylineInnerReceptionistBotState State;
	ESkylineInnerReceptionistBotExpression Expression;
	bool bForceCat = false;

	TPerPlayer<bool> PlayersOnTop;
	TPerPlayer<bool> InRange;
	TPerPlayer<bool> InAnnoyedRange;
	TPerPlayer<int> PlayerKarma;
	float ResetKarmaTimer = -0.0;
	AHazePlayerCharacter LookAtPlayer = nullptr;

	FTransform OGInterestPoint;
	FTransform InterestPoint;

	const float StopInFrontOfInterestDistance = 150.0;

	float TimeSinceHit = 0.0;
	int HitTimes = 0;
	FGravityBladeHitData LastHitData;
	float BrokenRandomizePixelsTimer = 0.0;

	float AfraidTimer = 0.0;
	float AnnoyedTimer = 0.0;

	bool bZoeGrabbedCup = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OGInterestPoint = ActorTransform;
		InterestPoint = ActorTransform;

		SetActorControlSide(Game::Mio);

		SpawnPixels();

		BladeResponseComp.OnHit.AddUFunction(this, n"OnBladeHit");
		WhipResponseComp.OnGrabbed.AddUFunction(this, n"OnWhipGrabbed");
		WhipResponseComp.OnReleased.AddUFunction(this, n"OnWhipReleased");

		if (GreetingsVolume != nullptr)
		{
			GreetingsVolume.OnActorBeginOverlap.AddUFunction(this, n"PlayerEnterGreetingRange");
			GreetingsVolume.OnActorEndOverlap.AddUFunction(this, n"PlayerLeftGreetingRange");
		}
		if (AnnoyedVolume != nullptr)
		{
			AnnoyedVolume.OnActorBeginOverlap.AddUFunction(this, n"PlayerEnterAnnoyedRange");
			AnnoyedVolume.OnActorEndOverlap.AddUFunction(this, n"PlayerLeftAnnoyedRange");
		}
		SyncedHeadLookDirection.SetValue(HeadMesh.ForwardVector);
		SmokeVFX.Deactivate();
		ElectricTicklingVFX.Deactivate();

		if (CoffeeCup != nullptr)
		{
			CoffeeCup.OnWhipSlingableGrabbed.AddUFunction(this, n"ZoeGrabbedCup");
			CoffeeCup.OnWhipSlingableObjectImpact.AddUFunction(this, n"ZoeThrewCup");
		}

		TopSphere.OnComponentBeginOverlap.AddUFunction(this, n"PlayerOnTop");
		TopSphere.OnComponentEndOverlap.AddUFunction(this, n"PlayerLeftOnTop");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FauxRoot.ApplyForce(HeadMesh.WorldLocation, FVector::UpVector * 500.0);
		HeadMesh.SetWorldRotation(FRotator::MakeFromXZ(SyncedHeadLookDirection.Value, FauxRoot.UpVector));

		UpdateStates(DeltaSeconds);
		HandleVFX();

		BrokenRandomizePixelsTimer -= DeltaSeconds;
		if (State == ESkylineInnerReceptionistBotState::Dead)
		{
			if (TimeSinceHit < 0.1 && !bLocalHasSetDark)
			{
				ResetAllPixelsLocal();
				{
					Expression = ESkylineInnerReceptionistBotExpression::Dark;
					FSkylineInnerReceptionistEventExpressionChangedParams Parms;
					Parms.Expression = Expression;
					USkylineInnerReceptionistEventHandler::Trigger_OnExpressionChanged(this, Parms);
					bLocalHasSetDark = true;
				}
			}
			else if (BrokenRandomizePixelsTimer < 0.0)
			{
				RandomizeAllPixelsLocal();
				BrokenRandomizePixelsTimer = 1.0 / 30.0;
				if (!bLocalHasSetAntWar)
				{
					Expression = ESkylineInnerReceptionistBotExpression::AntWar;
					FSkylineInnerReceptionistEventExpressionChangedParams Parms;
					Parms.Expression = Expression;
					USkylineInnerReceptionistEventHandler::Trigger_OnExpressionChanged(this, Parms);
					bLocalHasSetAntWar = true;
				}
			}
		}
		else
		{
			bLocalHasSetDark = false;
			bLocalHasSetAntWar = false;
		}
	}

	private void HandleVFX()
	{
		if (State == ESkylineInnerReceptionistBotState::Dead && !SmokeVFX.IsActive())
			SmokeVFX.Activate();
		if (State != ESkylineInnerReceptionistBotState::Dead && SmokeVFX.IsActive())
			SmokeVFX.Deactivate();

		if (State == ESkylineInnerReceptionistBotState::Laughing && !ElectricTicklingVFX.IsActive())
			ElectricTicklingVFX.Activate();
		if (State != ESkylineInnerReceptionistBotState::Laughing && ElectricTicklingVFX.IsActive())
			ElectricTicklingVFX.Deactivate();
	}

	private void UpdateStates(float DeltaSeconds)
	{
		TimeSinceHit += DeltaSeconds;
		if (!HasControl())
			return;

		ResetKarmaTimer -= DeltaSeconds;
		if (ResetKarmaTimer < 0.0)
		{
			PlayerKarma[Game::Mio] = 0;
			PlayerKarma[Game::Zoe] = 0;
		}

		if (TimeSinceHit > 5.0)
		{
			if (IsHit())
				SetState(ESkylineInnerReceptionistBotState::Schocked);
			HitTimes = 0;
		}

		if (State == ESkylineInnerReceptionistBotState::Afraid)
		{
			AfraidTimer += DeltaSeconds;
			if (AfraidTimer > 5.0 && !bZoeGrabbedCup)
				SetState(ESkylineInnerReceptionistBotState::Annoyed);
		}
		else
			AfraidTimer = 0.0;

		if (State == ESkylineInnerReceptionistBotState::Annoyed)
		{
			AnnoyedTimer += DeltaSeconds;
			if (AnnoyedTimer > 10.0 && !PlayersAreAnnoying())
				SetState(ESkylineInnerReceptionistBotState::Friendly);
		}
		else
			AnnoyedTimer = 0.0;
	}

	bool IsHit() const
	{
		if (State == ESkylineInnerReceptionistBotState::Hit1)
			return true;
		if (State == ESkylineInnerReceptionistBotState::Hit2)
			return true;
		return false;
	}

	bool HitOrDead() const
	{
		if (IsHit())
			return true;
		if (State == ESkylineInnerReceptionistBotState::Dead)
			return true;
		if (State == ESkylineInnerReceptionistBotState::Rebooting)
			return true;
		return false;
	}

	bool Busy() const
	{
		if (State == ESkylineInnerReceptionistBotState::ExterminateMode)
			return true;
		if (State == ESkylineInnerReceptionistBotState::Smug)
			return true;
		if (HitOrDead())
			return true;
		return false;
	}

	private void StartCountingKarmaTimer()
	{
		ResetKarmaTimer = 20.0;
	}

	void SetState(ESkylineInnerReceptionistBotState NewState)
	{
		ExpressionQueue.Empty();
		if (HasControl())
			CrumbSetState(NewState);
		if (NewState != ESkylineInnerReceptionistBotState::Friendly)
			bForceCat = false;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSetState(ESkylineInnerReceptionistBotState NewState)
	{
		State = NewState;
		if (NewState == ESkylineInnerReceptionistBotState::ExterminateMode)
		{
			BladeResponseComp.AddResponseComponentDisable(this);
			WhipTargetComp.Disable(this);
			PlayerKarma[Game::Mio] = 0;
			PlayerKarma[Game::Zoe] = 0;
		}
		else
		{
			BladeResponseComp.RemoveResponseComponentDisable(this);
			WhipTargetComp.Enable(this);
		}
	}

	void SetLookAtPlayer(AHazePlayerCharacter NewTarget)
	{
		if (LookAtPlayer != NewTarget)
		{
			ExpressionQueue.Empty();
			LookAtPlayer = NewTarget;
		}
	}

	private bool PlayersAreAnnoying()
	{
		return InAnnoyedRange[Game::Mio] || InAnnoyedRange[Game::Zoe];
	}

	bool PlayersAreOnTop()
	{
		return PlayersOnTop[Game::Mio] || PlayersOnTop[Game::Zoe];
	}

	UFUNCTION()
	private void PlayerEnterGreetingRange(AActor OverlappedActor, AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		InRange[Player] = true;
		if (State == ESkylineInnerReceptionistBotState::Working)
			SetState(ESkylineInnerReceptionistBotState::Greetings);

		FSkylineInnerReceptionistEventPlayerParams Parms;
		Parms.Player = Player;
		USkylineInnerReceptionistEventHandler::Trigger_OnReactToPlayerInGreetingRange(this, Parms);
	}

	UFUNCTION()
	private void PlayerLeftGreetingRange(AActor OverlappedActor, AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		InRange[Player] = false;
		if (!InRange[Player.OtherPlayer] && State != ESkylineInnerReceptionistBotState::Dead)
		{
			SetState(ESkylineInnerReceptionistBotState::Working);
		}
		FSkylineInnerReceptionistEventPlayerParams Parms;
		Parms.Player = Player;
		USkylineInnerReceptionistEventHandler::Trigger_OnReactToPlayerLeftGreetingRange(this, Parms);
	}

	UFUNCTION()
	private void PlayerEnterAnnoyedRange(AActor OverlappedActor, AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		InAnnoyedRange[Player] = true;
		if (State == ESkylineInnerReceptionistBotState::Friendly)
		{
			SetState(ESkylineInnerReceptionistBotState::WhatAREYouDOING);
		}
		FSkylineInnerReceptionistEventPlayerParams Parms;
		Parms.Player = Player;
		USkylineInnerReceptionistEventHandler::Trigger_OnReactToPlayerInAnnoyedRange(this, Parms);
	}

	UFUNCTION()
	private void PlayerLeftAnnoyedRange(AActor OverlappedActor, AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		InAnnoyedRange[Player] = false;
		if (!InAnnoyedRange[Player.OtherPlayer] && State == ESkylineInnerReceptionistBotState::Annoyed)
		{
			SetState(ESkylineInnerReceptionistBotState::Friendly);
		}
		FSkylineInnerReceptionistEventPlayerParams Parms;
		Parms.Player = Player;
		USkylineInnerReceptionistEventHandler::Trigger_OnReactToPlayerLeftAnnoyedRange(this, Parms);
	}

	private void SpawnPixels()
	{
		const float ScreenSizeX = 85.0;
		const float ScreenSizeY = 80.0;
		int Rows = 14;
		int Columns = 16;
		const float ColumnStep = ScreenSizeX / Columns;
		const float RowStep = ScreenSizeY / Rows;
		for (int iRow = 0; iRow < Rows; ++iRow)
		{
			CachedLitLamps.Add(FSkylineInnerReceptionistPixelRowExpression());
			PixelRows.Add(FSkylineInnerReceptionistPixelRow());
			for (int iColumn = 0; iColumn < Columns; ++iColumn)
			{
				FName PixelName = FName("Pixel_X" + iColumn + "Y" + iRow);
				USkylineInnerReceptionistPixelComponent Pixel = USkylineInnerReceptionistPixelComponent::Create(this, PixelName);
				Pixel.AttachToComponent(PixelsAttachment);
				Pixel.SetRelativeLocation(FVector(0.05, ColumnStep * -iColumn, RowStep * -iRow));
				Pixel.SetStaticMesh(PixelMesh);
				Pixel.SetMaterial(0, PixelDarkMaterial);
				Pixel.SetWorldScale3D(FVector::OneVector * 0.03);
				PixelRows[iRow].PixelMeshes.Add(Pixel);
				CachedLitLamps[iRow].Lits.Add(false);
			}
		}
	}

	void UpdateExpression(ESkylineInnerReceptionistBotExpression ExpressionType)
	{
		if (HasControl())
			CrumbSetExpression(CachedLitLamps, ExpressionType);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSetExpression(const TArray<FSkylineInnerReceptionistPixelRowExpression>& LitLamps, ESkylineInnerReceptionistBotExpression ExpressionName)
	{
		for (int iRow = 0; iRow < PixelRows.Num(); ++iRow)
		{
			for (int iColumn = 0; iColumn < PixelRows[iRow].PixelMeshes.Num(); ++iColumn)
			{
				if (LitLamps[iRow].Lits[iColumn])
				{
					if (State == ESkylineInnerReceptionistBotState::ExterminateMode)
						PixelRows[iRow].PixelMeshes[iColumn].SetMaterial(0, RedPixelMaterial);
					else
						PixelRows[iRow].PixelMeshes[iColumn].SetMaterial(0, PixelMaterial);
				}
				else
					PixelRows[iRow].PixelMeshes[iColumn].SetMaterial(0, PixelDarkMaterial);
			}
		}
		if (ExpressionName != Expression)
		{
			Expression = ExpressionName;
			FSkylineInnerReceptionistEventExpressionChangedParams Parms;
			Parms.Expression = Expression;
			USkylineInnerReceptionistEventHandler::Trigger_OnExpressionChanged(this, Parms);
		}
	}

	private void RandomizeAllPixelsLocal()
	{
		for (int iRow = 0; iRow < PixelRows.Num(); ++iRow)
		{
			for (int iColumn = 0; iColumn < PixelRows[iRow].PixelMeshes.Num(); ++iColumn)
			{
				PixelRows[iRow].PixelMeshes[iColumn].SetMaterial(0, Math::RandBool() ? PixelMaterial : PixelDarkMaterial);
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetDark()
	{
		ResetAllPixelsLocal();
	}

	private void ResetAllPixelsLocal()
	{
		for (int iRow = 0; iRow < PixelRows.Num(); ++iRow)
		{
			for (int iColumn = 0; iColumn < PixelRows[iRow].PixelMeshes.Num(); ++iColumn)
			{
				PixelRows[iRow].PixelMeshes[iColumn].SetMaterial(0, PixelDarkMaterial);
			}
		}
	}

	void LightPixelLocal(int X, int Y)
	{
		if (PixelRows.IsValidIndex(Y) && PixelRows[Y].PixelMeshes.IsValidIndex(X))
			PixelRows[Y].PixelMeshes[X].SetMaterial(0, PixelMaterial);
	}

	FVector GetDesiredLookDirection()
	{
		FVector TowardsInterestPoint = InterestPoint.Location - ActorLocation;
		TowardsInterestPoint.Z = 0.0;
		float DistanceToInterest = TowardsInterestPoint.Size();
		FVector DesiredLookDirection = TowardsInterestPoint.GetSafeNormal();
		if (DistanceToInterest < StopInFrontOfInterestDistance)
			DesiredLookDirection = InterestPoint.Rotation.ForwardVector;
		return DesiredLookDirection;
	}

	UFUNCTION()
	private void PlayerOnTop(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
		{
			PlayersOnTop[Player] = true;
			FSkylineInnerReceptionistEventPlayerParams Parms;
			Parms.Player = Player;
			USkylineInnerReceptionistEventHandler::Trigger_OnReactToPlayerStartOnTopOfReceptionist(this, Parms);
		}
	}

	UFUNCTION()
	private void PlayerLeftOnTop(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
		{
			PlayersOnTop[Player] = false;
			FSkylineInnerReceptionistEventPlayerParams Parms;
			Parms.Player = Player;
			USkylineInnerReceptionistEventHandler::Trigger_OnReactToPlayerStopOnTopOfReceptionist(this, Parms);
		}
	}

	UFUNCTION()
	private void ZoeGrabbedCup()
	{
		if (!Busy())
		{
			SetState(ESkylineInnerReceptionistBotState::Schocked);
			USkylineInnerReceptionistEventHandler::Trigger_OnReactToZoeGrabCup(this);
		}
		bZoeGrabbedCup = true;
	}

	UFUNCTION()
	private void ZoeThrewCup(TArray<FHitResult> HitResults, FVector Velocity)
	{
		bZoeGrabbedCup = false;
		PlayerKarma[Game::Zoe] = -1;
		StartCountingKarmaTimer();

		if (!Busy())
		{
			SetState(ESkylineInnerReceptionistBotState::Bracing);
			USkylineInnerReceptionistEventHandler::Trigger_OnReactToZoeThrowCup(this);
		}
	}

	UFUNCTION()
	private void OnWhipReleased(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		if (State == ESkylineInnerReceptionistBotState::Laughing)
		{
			SetState(ESkylineInnerReceptionistBotState::Friendly);
		}
	}

	UFUNCTION()
	private void OnWhipGrabbed(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		if (State == ESkylineInnerReceptionistBotState::Friendly)
		{
			SetState(ESkylineInnerReceptionistBotState::Laughing);
			PlayerKarma[Game::Zoe] = 1;
			StartCountingKarmaTimer();
		}
	}

	UFUNCTION()
	private void OnBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		FauxRoot.ApplyImpulse(HitData.ImpactPoint, -HitData.ImpactNormal * 500.0);
		TimeSinceHit = 0.0;
		if (State == ESkylineInnerReceptionistBotState::Dead)
			return;

		LastHitData = HitData;
		++HitTimes;
		if (HitTimes == 1)
			SetState(ESkylineInnerReceptionistBotState::Hit1);
		else if (HitTimes == 2)
			SetState(ESkylineInnerReceptionistBotState::Hit2);
		else if (State != ESkylineInnerReceptionistBotState::Dead)
		{
			PlayerKarma[Game::Mio] = -1;
			StartCountingKarmaTimer();
			SetState(ESkylineInnerReceptionistBotState::Dead);
		}

		USkylineInnerReceptionistEventHandler::Trigger_OnReactToMioBladeHitReceptionist(this);
	}

	/// DEV
#if EDITOR
	// Working,
	// Greetings,
	// Friendly,
	// Laughing,
	// Afraid,
	// Schocked,
	// Bracing,
	// WhatAREYouDOING,
	// Annoyed,
	// Hit1,
	// Hit2,
	// Dead,
	// Rebooting,
	// ExterminateMode,
	// Smug,

	UFUNCTION(DevFunction)
	private void TriggerStateHit()
	{
		SetState(ESkylineInnerReceptionistBotState::Hit1);
	}

	UFUNCTION(DevFunction)
	private void TriggerStateDead()
	{
		SetState(ESkylineInnerReceptionistBotState::Dead);
	}

	UFUNCTION(DevFunction)
	private void TriggerStateLaughing()
	{
		SetState(ESkylineInnerReceptionistBotState::Laughing);
	}

	UFUNCTION(DevFunction)
	private void TriggerStateBracing()
	{
		SetState(ESkylineInnerReceptionistBotState::Bracing);
	}

	UFUNCTION(DevFunction)
	private void TriggerStateSchocked()
	{
		SetState(ESkylineInnerReceptionistBotState::Schocked);
	}

	UFUNCTION(DevFunction)
	private void TriggerStateGreetings()
	{
		SetState(ESkylineInnerReceptionistBotState::Greetings);
	}

	UFUNCTION(DevFunction)
	private void TriggerStateFriendly()
	{
		bForceCat = false;
		SetState(ESkylineInnerReceptionistBotState::Friendly);
	}

	UFUNCTION(DevFunction)
	private void TriggerStateRebooting()
	{
		SetState(ESkylineInnerReceptionistBotState::Rebooting);
	}

	UFUNCTION(DevFunction)
	private void TriggerStateExterminate()
	{
		SetState(ESkylineInnerReceptionistBotState::ExterminateMode);
	}

	UFUNCTION(DevFunction)
	private void TriggerStateSmug()
	{
		SetState(ESkylineInnerReceptionistBotState::Smug);
	}

	UFUNCTION(DevFunction)
	private void TriggerStateAnnoyed()
	{
		SetState(ESkylineInnerReceptionistBotState::Annoyed);
	}

	UFUNCTION(DevFunction)
	private void Cat()
	{
		SetState(ESkylineInnerReceptionistBotState::Friendly);
		bForceCat = true;
	}


#endif
};