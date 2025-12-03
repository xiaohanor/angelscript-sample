event void FOnNightQueenMetalStartedMelting();
event void FOnNightQueenMetalMelted();
event void FOnNightQueenMetalRecovered();

event void FOnNightQueenMetalCollisionEnabled();
event void FOnNightQueenMetalCollisionDisabled();

class UNightQueenMetalComponent : USceneComponent
{

}

class ANightQueenMetal : AHazeActor
{
	UPROPERTY()
	FOnNightQueenMetalStartedMelting OnNightQueenMetalStartedMelting;
	UPROPERTY()
	FOnNightQueenMetalMelted OnNightQueenMetalMelted;
	UPROPERTY()
	FOnNightQueenMetalRecovered OnNightQueenMetalRecovered;
	UPROPERTY()
	FOnNightQueenMetalCollisionEnabled OnCollisionEnabled;
	UPROPERTY()
	FOnNightQueenMetalCollisionDisabled OnCollisionDisabled;

	UPROPERTY(DefaultComponent, RootComponent)
	UNightQueenMetalComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TempLogTransformComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UBoxComponent BlockingVolume;
	default BlockingVolume.SetCollisionProfileName(n"NoCollision");

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UNiagaraComponent NiagaraComp;
	default NiagaraComp.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);

	UPROPERTY(DefaultComponent, ShowOnActor)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 40000.0;

	UPROPERTY(DefaultComponent)
	UAcidResponseComponent AcidResponseComp;

	UPROPERTY(DefaultComponent)
	UTeenDragonAcidAutoAimComponent AutoAimComp;
	default AutoAimComp.AutoAimMaxAngle = 2.0;
	default AutoAimComp.bOnlyValidIfAimOriginIsWithinAngle = false;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"NightQueenMetalDissolvingCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"NightQueenMetalMeltingCapability");

	UPROPERTY(EditAnywhere, Category = "Regrowth")
	bool bHandleRegrowth = true;

	UPROPERTY(EditAnywhere, Category = "Regrowth", Meta = (EditCondition = bHandleRegrowth, EditConditionHides))
	bool bRegrowWithoutPoweredCrystal = false;

	UPROPERTY(EditAnywhere, Category = "Regrowth", Meta = (EditCondition = bHandleRegrowth, EditConditionHides))
	TArray<ASummitNightQueenGem> PoweringCrystals;

	UPROPERTY(EditAnywhere, Category = "Setup")
	protected UNightQueenMetalMeltingSettings MetalMeltingSettings;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TArray<AActor> AttachActors;

	UPROPERTY(DefaultComponent, Category = "Audio")
	USoundDefContextComponent SoundDefComp;

	// for now, a remap of MeltedAlpha
	UPROPERTY()
	float GreenGoAlpha;

	UPROPERTY()
	float MeltedAlpha;

	UPROPERTY()
	float MeltedAlphaTarget;

	UPROPERTY()
	float DissolveAlpha;

	UPROPERTY()
	float DissolveAlphaTarget;

	UPROPERTY()
	float TimeLastHit;

	UPROPERTY()
	float TimeLastDissolveStarted;

	UPROPERTY()
	bool bMelted = false;

	bool bCollisionIsOn = true;

	bool bEventRegrowRequested = false;

	TArray<UMaterialInstanceDynamic> MeltingMetalMaterials;

	UNightQueenMetalMeltingSettings CurrentSettings;

	TArray<AActor> OverlappingTeenDragons;

	UPROPERTY(EditAnywhere)
	bool bDebug;

	bool bForceRegrow;

	bool bMeshIsHidden = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (AttachActors.Num() > 0)
		{
			for (AActor Actor : AttachActors)
			{
				Actor.AttachToComponent(MeshRoot, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
			}
		}

		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");

		ApplyDefaultSettings(MetalMeltingSettings);
		CurrentSettings = UNightQueenMetalMeltingSettings::GetSettings(this);

		TArray<UStaticMeshComponent> MeshComps;
		GetComponentsByClass(MeshComps);

		for(auto Mesh : MeshComps)
		{
			auto MaterialInstance = Mesh.CreateDynamicMaterialInstance(0);
			for (int i = 0; i < Mesh.Materials.Num(); i++)
			{
				Mesh.SetMaterial(i, MaterialInstance);
				MeltingMetalMaterials.Add(MaterialInstance);
			}
		}

		for(int i = PoweringCrystals.Num() - 1; i >= 0; i--)
		{
			auto Crystal = PoweringCrystals[i];
			if(Crystal == nullptr)
			{
				PoweringCrystals.RemoveSingleSwap(Crystal);
				continue;
			}

			Crystal.OnSummitGemDestroyed.AddUFunction(this, n"RemovePoweringCrystal");
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnAcidHit(FAcidHit Hit)
	{
		if (MeltedAlphaTarget == 1.0)
		{
			if(!bMelted)
				UNightQueenMetalAcidEventHandler::Trigger_OnFullyMelted(this);

			bMelted = true;
			return;
		}
		else
			UNightQueenMetalAcidEventHandler::Trigger_OnAcidHit(this, Hit);

		if(MeltedAlphaTarget == 0)
			OnNightQueenMetalStartedMelting.Broadcast();
		if(CurrentSettings.bOneShotMetal)
		{
			MeltedAlphaTarget = 1.0;
		}
		else
		{
			MeltedAlphaTarget += (Hit.Damage/CurrentSettings.Health);
			MeltedAlphaTarget = Math::Clamp(MeltedAlphaTarget, 0.0, 1.0);
		}
		SetAlphaTarget(MeltedAlphaTarget);
	}

	private void SetAlphaTarget(float Alpha)
	{
		MeltedAlphaTarget = Alpha;
		TimeLastHit = Time::GameTimeSeconds;
	}

	void AddPoweringCrystal(ASummitNightQueenGem NewCrystal)
	{
		if(PoweringCrystals.Contains(NewCrystal))
			return;

		PoweringCrystals.Add(NewCrystal);
	}

	UFUNCTION(NotBlueprintCallable)
	void RemovePoweringCrystal(ASummitNightQueenGem DestroyedCrystal)
	{
		PoweringCrystals.RemoveSingleSwap(DestroyedCrystal);

		if(PoweringCrystals.Num() == 0)
		{
			SetPermaMelting();
		}
	}

	void SetPermaMelting()
	{
		bHandleRegrowth = false;
		DissolveAlphaTarget = 1.0;
	}

	void SetMeltedAmountInstantly(float MeltedAmount)
	{
		float ClampedMeltedAmount = Math::Clamp(MeltedAmount, 0, 1);

		MeltedAlphaTarget = ClampedMeltedAmount;
		MeltedAlpha = ClampedMeltedAmount;

		SetMeltedMaterials(ClampedMeltedAmount);
	}

	UFUNCTION(BlueprintCallable)
	void TriggerRegrow()
	{
		bEventRegrowRequested = true;
	}

	void SetDissolvedAmountInstantly(float DissolvedAmount)
	{
		float ClampedDissolvedAmount = Math::Clamp(DissolvedAmount, 0, 1);

		DissolveAlphaTarget = ClampedDissolvedAmount;
		DissolveAlpha = ClampedDissolvedAmount;

		SetDissolveMaterials(ClampedDissolvedAmount);
	}

	void InitMeltedMaterials()
	{
		for(auto Metal : MeltingMetalMaterials)
		{
			Metal.SetScalarParameterValue(n"TimestampMeltStarted", Time::GetGameTimeSeconds());
		}
	}

	void SetMeltedMaterials(float Blend)
	{
		for(auto Metal : MeltingMetalMaterials)
		{
			Metal.SetScalarParameterValue(n"BlendMelt", Blend);
		}
	}

	void SetDissolveMaterials(float Blend)
	{
		// blend away
		for(auto Metal : MeltingMetalMaterials)
		{
			Metal.SetScalarParameterValue(n"BlendDissolve", Blend);
		}

		// hide once fully dissolved
		if(Math::IsNearlyEqual(Blend, 1.0))
		{
			if(!bMeshIsHidden)
			{
				MeshComp.AddComponentVisualsAndCollisionAndTickBlockers(this);
				bMeshIsHidden = true;
			}
		}
		else
		{
			if(bMeshIsHidden)
			{
				MeshComp.RemoveComponentVisualsAndCollisionAndTickBlockers(this);
				bMeshIsHidden = false;
			}
		}
	}

	void ToggleCollision(bool bTurnOn)
	{
		if(bTurnOn)
		{
			RemoveActorCollisionBlock(this);
			NiagaraComp.Activate();
			bCollisionIsOn = true;
			AutoAimComp.Enable(this);
			OnCollisionEnabled.Broadcast();
		}
		else
		{
			AddActorCollisionBlock(this);
			NiagaraComp.Deactivate();
			bCollisionIsOn = false;
			AutoAimComp.Disable(this);
			OnCollisionDisabled.Broadcast();
		}
	}

	UFUNCTION()
	void ActivateForceRegrow()
	{
		bForceRegrow = true;
	}

	UFUNCTION()
	void ResetMetal()
	{
		SetMeltedAmountInstantly(0.0);
		SetDissolvedAmountInstantly(0.0);
		ToggleCollision(true);
	}

	bool PlayerIsInsideBlockingVolume()
	{
		if(!CurrentSettings.bDontRegrowWhenPlayerInArea)
			return false;

		FHazeTraceSettings Trace;
		Trace = Trace::InitChannel(ECollisionChannel::PlayerCharacter);
		Trace.UseBoxShape(BlockingVolume.BoundingBoxExtents, BlockingVolume.WorldRotation.Quaternion());
		auto HitResults = Trace.QueryOverlaps(BlockingVolume.WorldLocation);

		if(!HitResults.HasOverlapHit())
			return false;
		
		for(auto Overlap : HitResults.OverlapHits)
		{
			auto Player = Cast<AHazePlayerCharacter>(Overlap.Actor);

			if(Player != nullptr)
				return true;
		}
		return false; // None of the overlaps were players
	}

	bool ShouldUnDissolve()
	{
		if(bEventRegrowRequested)
			return true;

		if(!bHandleRegrowth)
			return false;
		
		if(Time::GetGameTimeSince(TimeLastDissolveStarted) < CurrentSettings.UnDissolveDelay)
			return false;

		if(PlayerIsInsideBlockingVolume())
			return false;

		if(PoweringCrystals.Num() > 0 || bRegrowWithoutPoweredCrystal)
			return true;

		return false;
	}

	bool ShouldRegrow()
	{
		if (bForceRegrow)
		{
			bForceRegrow = false;
			return true;
		}

		if(!bHandleRegrowth)
			return false;
		
		if(PoweringCrystals.Num() == 0)
			return false;


		if(Time::GetGameTimeSince(TimeLastHit) < CurrentSettings.RegrowthDelay.GetFloatValue(MeltedAlpha))
			return false;

		return true;
	}

	UFUNCTION(CallInEditor, Category = "Regrowth", Meta = (EditCondition = bHandleRegrowth, EditConditionHides))
	void LinkupCrystal()
	{
	#if EDITOR
		// For syncing lists in crystal and metal in editor

		TArray<ASummitNightQueenGem> LevelCrystalActors = Editor::GetAllEditorWorldActorsOfClass(ASummitNightQueenGem);

		for(auto Crystal : LevelCrystalActors)
		{
			auto Gem = Cast<ASummitNightQueenGem>(Crystal);

			if(PoweringCrystals.Contains(Gem))
			{
				if(!Gem.PoweringMetalPieces.Contains(this))
				{
					Gem.PoweringMetalPieces.AddUnique(this);
				}
			}
			else
			{
				if(Gem.PoweringMetalPieces.Contains(this))
				{
					Gem.PoweringMetalPieces.RemoveSingleSwap(this);
				}
			}
		}

		// Remove duplicates of crystals when changing the reference
		for(int i = PoweringCrystals.Num() - 1; i >= 0; i--)
		{
			auto Crystal = PoweringCrystals[i];

			if(Crystal == nullptr)
				continue;

			for(int j = i - 1; j >= 0; j--)
			{
				auto OtherCrystal = PoweringCrystals[j];

				if(OtherCrystal == nullptr)
					continue;

				if(Crystal == OtherCrystal)
				{
					RemovePoweringCrystal(OtherCrystal);
				}
			}
		}
	#endif
	}
}