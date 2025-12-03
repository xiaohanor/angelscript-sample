event void FIslandSidescrollerShootableScrewSignature();

UCLASS(Abstract)
class AIslandSidescrollerShootableScrew : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UIslandRedBlueImpactOverchargeResponseComponent OverchargeComp;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UIslandRedBlueTargetableComponent Targetable;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	USceneComponent EffectLocationComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UIslandSidescrollerShootableScrewVisualizerComponent VisualizerComp;
#endif

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;

	UPROPERTY(EditDefaultsOnly)
	UIslandRedBlueImpactOverchargeResponseComponentSettingsDataAsset MioSettings;

	UPROPERTY(EditDefaultsOnly)
	UIslandRedBlueImpactOverchargeResponseComponentSettingsDataAsset ZoeSettings;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditAnywhere)
	float AmountOfTurnsForFullAlpha = 1.0;

	UPROPERTY(EditAnywhere)
	float ScrewMoveOutDistance = 200.0;

	UPROPERTY(EditAnywhere)
	float AdditionalScrewSnapDistance = 40.0;

	UPROPERTY(EditAnywhere)
	float AdditionalScrewSnapAccelerationDuration = 0.15;

	UPROPERTY(EditAnywhere)
	float AccelerationDuration = 1.0;

	UPROPERTY(EditAnywhere)
	FVector ScrewOutDirectionActorSpace = FVector(-1.0, 0.0, 0.0);

	UPROPERTY(EditAnywhere)
	bool bReverseDirection = true;

	UPROPERTY(EditInstanceOnly)
	EHazePlayer UsableByPlayer;
	default UsableByPlayer = EHazePlayer::Mio;

	UPROPERTY(EditAnywhere)
	bool bDoOnce;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	bool bIsDisabled;

	UPROPERTY(EditAnywhere)
	bool bAllowShootingOnCompleted;

	UPROPERTY()
	FIslandSidescrollerShootableScrewSignature OnCompleted;

	UPROPERTY()
	FIslandSidescrollerShootableScrewSignature OnImpact;

	UPROPERTY()
	FIslandSidescrollerShootableScrewSignature OnOvercharged;
	
	UPROPERTY()
	FIslandSidescrollerShootableScrewSignature OnDischarging;

	UPROPERTY()
	FIslandSidescrollerShootableScrewSignature OnReset;

	UPROPERTY()
	bool bIsOvercharged;
	bool bIsDischarging;

	FHazeAcceleratedFloat AcceleratedAlpha;
	FHazeAcceleratedFloat AcceleratedAdditionalSnapDistance;
	bool bIsCompleted = false;
	uint LastImpactFrame;
	AHazePlayerCharacter LastImpactPlayer;
	AIslandSidescrollerShootableScrewListener ScrewListener;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(UsableByPlayer == EHazePlayer::Mio)
		{
			OverchargeComp.SettingsDataAsset_Property = MioSettings;
		}
		else
		{
			OverchargeComp.SettingsDataAsset_Property = ZoeSettings;
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::GetPlayer(UsableByPlayer));
		AcceleratedAlpha.SnapTo(OverchargeComp.ChargeAlpha);

		if(bReverseDirection)
			AcceleratedAdditionalSnapDistance.SnapTo(AdditionalScrewSnapDistance);
		else
			AcceleratedAdditionalSnapDistance.SnapTo(0.0);

		OverchargeComp.OnImpactEvent.AddUFunction(this, n"HandleImpact");
		OverchargeComp.OnFullCharge.AddUFunction(this, n"HandleFullAlpha");
		OverchargeComp.OnStartDischarging.AddUFunction(this, n"HandleDischarging");
		OverchargeComp.OnZeroCharge.AddUFunction(this, n"HandleOnZeroCharge");

		OverchargeComp.BlockImpactForPlayer(Game::GetOtherPlayer(UsableByPlayer), this);
		Targetable.DisableForPlayer(Game::GetOtherPlayer(UsableByPlayer), this);

		if (bIsDisabled)
			DisableScrew();
		
		if(bDoOnce)
		{
			OverchargeComp.Settings_Property.bBlockDischargeWhenFull = true;

			if(OverchargeComp.SettingsDataAsset_Property != nullptr)
			{
				auto SettingsDataAsset = Cast<UIslandRedBlueImpactOverchargeResponseComponentSettingsDataAsset>(NewObject(this, OverchargeComp.SettingsDataAsset_Property.Class));

				SettingsDataAsset.Settings = OverchargeComp.SettingsDataAsset_Property.Settings;
				SettingsDataAsset.Settings.bBlockDischargeWhenFull = true;
				OverchargeComp.SettingsDataAsset_Property = SettingsDataAsset;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		AcceleratedAlpha.AccelerateTo(OverchargeComp.ChargeAlpha, AccelerationDuration, DeltaTime);

		float Alpha = AcceleratedAlpha.Value;
		if(bReverseDirection)
			Alpha = 1.0 - Alpha;

		float RawChargeAlpha = OverchargeComp.ChargeAlpha;
		if(bReverseDirection)
			RawChargeAlpha = 1.0 - RawChargeAlpha;

		if(RawChargeAlpha == 0.0)
			AcceleratedAdditionalSnapDistance.AccelerateTo(0.0, AdditionalScrewSnapAccelerationDuration, DeltaTime);
		else if(RawChargeAlpha == 1.0)
			AcceleratedAdditionalSnapDistance.AccelerateTo(AdditionalScrewSnapDistance, AdditionalScrewSnapAccelerationDuration, DeltaTime);

		float Delta = ScrewMoveOutDistance * Alpha + AcceleratedAdditionalSnapDistance.Value;

		Mesh.RelativeLocation = ScrewOutDirectionActorSpace * Delta;
		Mesh.RelativeLocation /= ActorScale3D.X;
		
		float RotationAlpha = Delta / (ScrewMoveOutDistance + AdditionalScrewSnapDistance);
		Mesh.RelativeRotation = Math::RotatorFromAxisAndAngle(ScrewOutDirectionActorSpace, 360.0 * AmountOfTurnsForFullAlpha * RotationAlpha);
	}

	UFUNCTION()
	void HandleFullAlpha(bool bWasOvercharged)
	{
		if(!bAllowShootingOnCompleted)
		{
			if (bIsOvercharged == true)
				return;
		}

		if(bDoOnce)
			UIslandSidescrollerShootableScrewEffectHandler::Trigger_OnHoldFullyCharged(this, FIslandSidescrollerShootableScrewEffectParams(this));
		else
			UIslandSidescrollerShootableScrewEffectHandler::Trigger_OnFullyCharged(this, FIslandSidescrollerShootableScrewEffectParams(this));

		OnOvercharged.Broadcast();
		OnCompleted.Broadcast();

		bIsOvercharged = true;

		if(!bAllowShootingOnCompleted)
		{
			DisableImpacts();

			if (bDoOnce)
			{
				bIsCompleted = true;
			}
		}

		if (CameraShake != nullptr)
		{
			Game::GetMio().PlayCameraShake(CameraShake, this, 1.0);
			Game::GetZoe().PlayCameraShake(CameraShake, this, 1.0);
		}

		BP_HandleFullAlpha();

		if (ScrewListener != nullptr)
		{
			ScrewListener.CheckChildren();
		}
	}

	UFUNCTION()
	void HandleImpact(FIslandRedBlueImpactResponseParams ImpactData)
	{
		if (bIsDisabled)
			return;

		OnImpact.Broadcast();

		if (!bAllowShootingOnCompleted)
		{
			if (bDoOnce && bIsOvercharged)
				return;
		}

		bIsDischarging = false;
		LastImpactFrame = Time::FrameNumber;
		LastImpactPlayer = ImpactData.Player;

		if(IslandRedBlueWeapon::PlayerCanHitOverchargeComponent(ImpactData.Player, OverchargeComp.OverchargeColor))
		{
			UIslandSidescrollerShootableScrewEffectHandler::Trigger_OnGoodProjectileHit(this, FIslandSidescrollerShootableScrewEffectParams(this));

			if(HasControl() && OverchargeComp.PreviousChargeAlpha == 0.0)
				CrumbOnStartCharging();
		}
		else if(OverchargeComp.Settings.bDischargeOnWrongColor)
		{
			UIslandSidescrollerShootableScrewEffectHandler::Trigger_OnBadProjectileHit(this, FIslandSidescrollerShootableScrewEffectParams(this));
		}

		if (!bAllowShootingOnCompleted)
		{
			if (bIsOvercharged)
				return;
		}

		BP_HandleImpact();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnStartCharging()
	{
		UIslandSidescrollerShootableScrewEffectHandler::Trigger_OnStartCharging(this, FIslandSidescrollerShootableScrewEffectParams(this));
	}

	UFUNCTION()
	void HandleDischarging(bool bCurrentlyAtFullCharge)
	{
		bIsDischarging = true;

		if (!bCurrentlyAtFullCharge)
			return;

		if(!bIsCompleted)
			UIslandSidescrollerShootableScrewEffectHandler::Trigger_OnStartDischarging(this, FIslandSidescrollerShootableScrewEffectParams(this));

		BP_OnDischarging();
		OnDischarging.Broadcast();
		bIsOvercharged = false;
	}

	UFUNCTION()
	void HandleOnZeroCharge(bool bCurrentlyAtFullCharge)
	{
		if(!bIsCompleted)
			UIslandSidescrollerShootableScrewEffectHandler::Trigger_OnChargeReset(this, FIslandSidescrollerShootableScrewEffectParams(this));

		if (bDoOnce)
			return;

		if (bCurrentlyAtFullCharge)
		{
			OnReset.Broadcast();

			if (bIsDisabled)
				return;

			EnableImpacts();
			
			if (ScrewListener != nullptr)
			{
				ScrewListener.bFinished = false;
				ScrewListener.CheckChildren();
			}
		}
	}

	// Will stop movement of the screw and disable impacts!
	UFUNCTION()
	void EnableScrew()
	{
		if (bIsCompleted)
			return;

		EnableImpacts();
		OverchargeComp.SetComponentTickEnabled(true);
		bIsDisabled = false;
	}

	UFUNCTION()
	void DisableScrew()
	{
		DisableImpacts();
		OverchargeComp.SetComponentTickEnabled(false);
		bIsDisabled = true;
	}

	UFUNCTION()
	void EnableImpacts()
	{
		OverchargeComp.UnblockImpactForPlayer(Game::GetPlayer(UsableByPlayer), this);
		Targetable.Enable(this);
	}

	UFUNCTION()
	void DisableImpacts()
	{
		OverchargeComp.BlockImpactForPlayer(Game::GetPlayer(UsableByPlayer), this);
		Targetable.Disable(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_HandleImpact() {}

	UFUNCTION(BlueprintEvent)
	void BP_HandleFullAlpha() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnDischarging() {}

	// Will get the current charge alpha of how charged this screw is.
	UFUNCTION(BlueprintPure)
	float GetCurrentCharge() const
	{
		if(bIsCompleted)
			return 1.0;

		return OverchargeComp.ChargeAlpha;
	}

	// Will return 1 if the screw was shot and charged this frame, 0 if the charge didn't change.
	// -1 if it is currently discharging
	UFUNCTION(BlueprintPure)
	int GetCurrentChargeDirection() const
	{
		if(bIsCompleted)
			return 0.0;

		if(OverchargeComp.IsDischarging())
			return -1;

		if(LastImpactFrame == Time::FrameNumber)
		{
			if(IslandRedBlueWeapon::PlayerCanHitOverchargeComponent(LastImpactPlayer, OverchargeComp.OverchargeColor))
				return 1;
			else if(OverchargeComp.Settings.bDischargeOnWrongColor)
				return -1;
		}

		return 0;
	}
}

struct FIslandSidescrollerShootableScrewEffectParams
{
	FIslandSidescrollerShootableScrewEffectParams(AIslandSidescrollerShootableScrew In_Screw)
	{
		Screw = In_Screw;
	}

	UPROPERTY()
	AIslandSidescrollerShootableScrew Screw;
}

UCLASS(Abstract)
class UIslandSidescrollerShootableScrewEffectHandler : UHazeEffectEventHandler
{
	// Triggers when a projectile of the same color as the screw hits.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGoodProjectileHit(FIslandSidescrollerShootableScrewEffectParams Params) {}

	// Triggers when a projectile of the opposite color as the screw hits.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBadProjectileHit(FIslandSidescrollerShootableScrewEffectParams Params) {}

	// Triggers when the charge goes from 0 to above 0.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartCharging(FIslandSidescrollerShootableScrewEffectParams Params) {}

	// Triggers when the charge starts moving towards 0.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartDischarging(FIslandSidescrollerShootableScrewEffectParams Params) {}

	// Triggers when the charge goes from above 0 to 0.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnChargeReset(FIslandSidescrollerShootableScrewEffectParams Params) {}

	// Triggers when the charge goes from below 1 to 1 and it will eventually discharge.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFullyCharged(FIslandSidescrollerShootableScrewEffectParams Params) {}

	// Triggers when the charge goes from below 1 to 1 and it will stay fully charged forever.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHoldFullyCharged(FIslandSidescrollerShootableScrewEffectParams Params) {}
}

#if EDITOR
class UIslandSidescrollerShootableScrewVisualizerComponent : UActorComponent
{
	default bIsEditorOnly = true;
}

class UIslandSidescrollerShootableScrewVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UIslandSidescrollerShootableScrewVisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Screw = Cast<AIslandSidescrollerShootableScrew>(Component.Owner);

		auto Material = Cast<UMaterialInterface>(LoadObject(nullptr, KineticActorVisualizer::MainMaterialPath));

		FVector Direction = Screw.ActorTransform.TransformVectorNoScale(Screw.ScrewOutDirectionActorSpace);
		FTransform Transform = FTransform(Screw.ActorRotation, Screw.ActorLocation + Direction * (Screw.ScrewMoveOutDistance + Screw.AdditionalScrewSnapDistance), Screw.ActorScale3D);
		KineticActorVisualizer::DrawAllStaticMeshesOnActor(this, Screw, Transform, Material);
	}
}
#endif