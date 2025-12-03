event void FSummitMeltComponentOnMelted();
event void FSummitMeltComponentOnRestored();

class USummitMeltComponent : UActorComponent
{
	private TArray<FInstigator> Disablers;

	USummitMeltSettings Settings;

	UPROPERTY(EditAnywhere)
	USummitMeltSettings DefaultMeltSettings;

	UPROPERTY()
	FSummitMeltComponentOnMelted OnMelted;
	UPROPERTY()
	FSummitMeltComponentOnRestored OnRestored;

	UPROPERTY(EditAnywhere)
	bool bMeltAllMaterials = true;

	TArray<UMaterialInstanceDynamic> MeltingMetalMaterials;
	TArray<USummitMeltPartComponent> Parts;

	UPROPERTY(BlueprintReadOnly)
	float Health = 1.0;

	// things are broken. need to make this public to revert back 
	// to how it was before so we have something that is working again
	UPROPERTY(BlueprintReadOnly)
	float GreenGooAlpha;

	private FHazeAcceleratedFloat AccMeltAlpha;
	private float LastMeltTime;

	bool GetbMelted() const property
	{
		return AccMeltAlpha.Value > 0.999;
	}

	bool GetbDissolved() const property
	{
		return DissolveAlpha >= 1.0;
	}

	UPROPERTY(BlueprintReadOnly)
	float DissolveAlpha;

	private float DissolveTimer;
	private float DissolvedTime;
	private float AdditionalStayDissolvedDuration;

	// Permits setting custom index of the meltable material.
	int MeltMaterialIndex = 0;

	UFUNCTION(BlueprintPure)
	float GetDissolveLoopTime() const
	{
		return Settings.DissolveDuration 
		+ Settings.StayDissolvedDuration
		+ Settings.RestoreDuration;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AHazeActor HazeOwner = Cast<AHazeActor>(Owner);

		if(DefaultMeltSettings != nullptr)
			HazeOwner.ApplySettings(DefaultMeltSettings, this);
		Settings = USummitMeltSettings::GetSettings(HazeOwner);
		Health = Settings.MaxHealth;

		GreenGooAlpha = 0.0;
		AccMeltAlpha.SnapTo(0.0);
		DissolveAlpha = 0.0;

		auto AcidResponse = UAcidResponseComponent::GetOrCreate(Owner);		
		AcidResponse.OnAcidHit.AddUFunction(this, n"OnAcidHit");

		Owner.GetComponentsByClass(Parts);

		AHazeCharacter HazeCharacter = Cast<AHazeCharacter>(Owner);
		if(HazeCharacter != nullptr)
		{
			UMaterialInstanceDynamic MaterialInstance = HazeCharacter.Mesh.CreateDynamicMaterialInstance(MeltMaterialIndex);
			if(MaterialInstance != nullptr)
			{
				if (bMeltAllMaterials)
				{
					// Assigns same dynamic material to all materials on the mesh.
					int MaterialsNum = HazeCharacter.Mesh.Materials.Num();
					for (int i = 0; i < MaterialsNum; i++)
					{
						HazeCharacter.Mesh.SetMaterial(i, MaterialInstance);
						MeltingMetalMaterials.Add(MaterialInstance);
					}
				}
				else
				{
					// Only make the specified material index meltable.
					HazeCharacter.Mesh.SetMaterial(MeltMaterialIndex, MaterialInstance);
					MeltingMetalMaterials.Add(MaterialInstance);
				}
			}
		}

		auto RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		if (RespawnComp != nullptr)
			RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");

		MeltDevToggles::ShowMeltAlphas.MakeVisible();
	}

	UFUNCTION()
	void OnReset()
	{
		Health = Settings.MaxHealth;
		Restore(Settings.RestoreDuration);
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit Hit)
	{
		if(Disablers.Num() > 0)
			return;

		if (AccMeltAlpha.Value > 0.999)
		{
			if(AdditionalStayDissolvedDuration < Settings.AdditionalStayDissolvedMaxDuration)
				AdditionalStayDissolvedDuration += Settings.AdditionalStayDissolvedRate * Hit.Damage;
			return;
		}
		
		TakeDamage(Hit.Damage);
	}

	private void TakeDamage(float Damage)
	{
		Health = Math::Clamp(Health - Damage, 0.0, Settings.MaxHealth);
		LastMeltTime = Time::GetGameTimeSeconds();

		if (Game::GetMio().HasControl() && !bMelted && (Health < SMALL_NUMBER))
		{
			CrumbMelted();
		}
	}

	// based on health fraction
	void UpdateMeltAlpha()
	{
		const float ClampedHealth = Math::Clamp(Health, Settings.MinHealth, Settings.MaxHealth);
		const float HealthFraction = ClampedHealth / Settings.MaxHealth;

		// Green go value will rise as health decreases
		// float GreenGooTarget = Math::GetMappedRangeValueClamped(
		// 	FVector2D(1.0, Settings.GreenGooEndFraction), 
		// 	FVector2D(0.0, 1.0), 
		// 	HealthFraction
		// );
		// AccGreenGooAlpha.AccelerateTo(GreenGooTarget, 0.8, DeltaTime);
		// AccGreenGooAlpha.AccelerateTo(GreenGooTarget, 0.0, DeltaTime);

		float MeltTarget = Math::GetMappedRangeValueClamped(
			FVector2D(Settings.MeltStartFraction, 0.0), 
			FVector2D(0.0, 1.0),
			HealthFraction
		);

		// Snap the value for now. Because we are getting bugs where
		// bMelted == true but MeltAlpha < 1.0 due to it being updated next frame. 
		AccMeltAlpha.SnapTo(MeltTarget);
		// AccMeltAlpha.AccelerateTo(MeltTarget, 0.8, DeltaTime);

		// PrintToScreen("GreenGoTarget " + GreenGooTarget + " | HealthFraction: " + HealthFraction);
		// PrintToScreen("MeltTarget " + MeltTarget + " | HealthFraction: " + HealthFraction);

		// make sure we update it immediately and not wait until next frame.
		UpdateMeltAlphaOnMaterials();
	}

	void UpdateMeltAlphaOnMaterials()
	{
		for(USummitMeltPartComponent Part: Parts)
		{
			Part.SetMeltedMaterials(AccMeltAlpha.Value);
		}

		for(UMaterialInstanceDynamic Metal : MeltingMetalMaterials)
		{
			Metal.SetScalarParameterValue(n"BlendMelt", AccMeltAlpha.Value);
		}
	}

	void UpdateDissolveAlphaOnMaterials()
	{
		for(UMaterialInstanceDynamic Metal : MeltingMetalMaterials)
		{
			Metal.SetScalarParameterValue(n"BlendDissolve", DissolveAlpha);
		}

		for(USummitMeltPartComponent Part: Parts)
		{
			Part.SetDissolveMaterials(DissolveAlpha);
		}
	}

	void UpdateDissolveAlpha(const float DeltaTime)
	{
		// PrintToScreen("MeltAlpha: " + GetMeltAlpha());
		// PrintToScreen("DissolveAlpha: " + DissolveAlpha);
		// PrintToScreen("Dissolved: " + bDissolved);
		// PrintToScreen("Melted: " + bMelted);

		if(bMelted && !bDissolved)
		{
			Dissolve(DeltaTime);
		}
		else if(ShouldRestore())
		{
			Restore(DeltaTime);
		}
	}

	void Update(float DeltaTime)
	{
		UpdateMeltAlpha();
		UpdateDissolveAlpha(DeltaTime);
		UpdateDebug();
	}

	void UpdateDebug()
	{
		if (MeltDevToggles::ShowMeltAlphas.IsEnabled())
		{
			FVector2D UV;
			auto Mio = Game::GetMio();
			bool bOnScreen = SceneView::ProjectWorldToViewpointRelativePosition(Mio, Owner.GetActorLocation(), UV);
			auto MioCameraDir = Mio.ViewRotation.ForwardVector;
			const FVector Delta = (Owner.GetActorLocation() - Mio.ViewLocation);
			const float DeltaDistance = Delta.Size();
			const FVector DeltaNormalized = Delta.GetSafeNormal();
			const bool bChoosenOne = DeltaNormalized.DotProduct(MioCameraDir) > 0.9;

			bool bIncomingProjectiles = Acid::GetAcidManager().Projectiles.Num() > 0;
			bool bHasBeenHit = Health < Settings.MaxHealth;

			// if(bOnScreen && (bHasBeenHit || bIncomingProjectiles) && bChoosenOne)
			if(true)
			{
				FVector Center;
				FVector Extents; 
				Owner.GetActorBounds(true, Center, Extents);
				FVector Loc = Center; 
				Loc.Z += Extents.Z;

				float HealthFraction = Math::Saturate(Health / Settings.MaxHealth);

				Debug::DrawDebugString(Loc + FVector(0.0, 0.0, 1000.0), "bMelted: " + bMelted,
				bMelted ? FLinearColor::Green : FLinearColor::Red,
				Scale = 2.0
				);

				Debug::DrawDebugString(Loc + FVector(0.0, 0.0, 700.0), "bDissolved: " + bDissolved,
				bDissolved ? FLinearColor::Green : FLinearColor::Red,
				Scale = 2.0
				);

				Debug::DrawDebugString(Loc + FVector(0.0, 0.0, 450.0), " Health: " + HealthFraction, FLinearColor::White, Scale = 2.0);
				Debug::DrawDebugString(Loc + FVector(0.0, 0.0, 300.0), "    Goo: " + GreenGooAlpha, FLinearColor::Green, Scale = 2.0);
				Debug::DrawDebugString(Loc + FVector(0.0, 0.0, 150.0), "   Melt: " + AccMeltAlpha.Value, FLinearColor::Yellow, Scale = 2.0);
				Debug::DrawDebugString(Loc + FVector(0.0, 0.0, 0.0), "Dissolve: " + DissolveAlpha, FLinearColor::LucBlue, Scale = 2.0);
			}
		}
	}

	private void Dissolve(float DeltaTime)
	{
		if (bDissolved)
			return;

		DissolveTimer += DeltaTime;
		DissolveAlpha = Math::Clamp(DissolveTimer / Settings.DissolveDuration, 0.0, 1.0);

		if (DissolveAlpha >= 1)
		{
			DissolveTimer = 0.0;
			DissolvedTime = Time::GetGameTimeSeconds();
		}

		// make sure we update it immediately and not wait until next frame.
		UpdateDissolveAlphaOnMaterials();
	}

	private void Restore(float DeltaTime)
	{
		float RestoreDelta = DeltaTime / Math::Max(0.01, Settings.RestoreDuration);
		Health = Math::Clamp(Health + RestoreDelta * Settings.MaxHealth, Settings.MinHealth, Settings.MaxHealth);
		DissolveAlpha = Math::Clamp(DissolveAlpha - RestoreDelta, 0.0, 1.0);

		if((DissolveAlpha < SMALL_NUMBER) && (Health > Settings.MaxHealth - SMALL_NUMBER))
		{
			UpdateMeltAlpha();
			OnRestored.Broadcast();
		}

		// make sure we update it immediately and not wait until next frame.
		UpdateDissolveAlphaOnMaterials();
	}

	float GetTimeSinceLastMelt() const
	{
		return Time::GetGameTimeSince(LastMeltTime);
	}

	bool ShouldRestore()
	{
		if ((Health > Settings.MaxHealth - SMALL_NUMBER) && (AccMeltAlpha.Value < SMALL_NUMBER) && (DissolveAlpha < SMALL_NUMBER))
			return false; // Done restoring

		if(!bDissolved && !bMelted && GetTimeSinceLastMelt() > Settings.StayMeltedDuration)
			return true; // Not fully melted, can restore after stay melted duration

		if(bDissolved && (Time::GetGameTimeSince(DissolvedTime) > Settings.StayDissolvedDuration + AdditionalStayDissolvedDuration))
			return true; // Fully melted or dissolved need to wait for dissolve duration to pass 
		
		return false;
	}
	
	void ImmediateRestore()
	{
		// Start restoring immediately
		DissolvedTime = -BIG_NUMBER; 
		LastMeltTime = -BIG_NUMBER;
		Health = Settings.MaxHealth;
	}

	UFUNCTION()
	void ImmediateMelt()
	{
		TakeDamage(Settings.MaxHealth);
	}

	UFUNCTION(CrumbFunction)
	void CrumbMelted()
	{
		UpdateMeltAlpha();

		AdditionalStayDissolvedDuration = 0;
		OnMelted.Broadcast();
	}

	UFUNCTION()
	void DisableMelting(FInstigator Instigator)
	{
		Disablers.AddUnique(Instigator);
	}

	UFUNCTION()
	void EnableMelting(FInstigator Instigator)
	{
		Disablers.Remove(Instigator);
	}

	bool HasFullHealth() const
	{
		return Health >= Settings.MaxHealth;
	}

	UFUNCTION()
	float GetMeltAlpha() const property
	{
		return AccMeltAlpha.Value;
	}

	UFUNCTION()
	void GetAlphas(float& OutGreenGooAlpha, float& OutMeltAlpha, float& OutDissolveAlpha)
	{
		OutGreenGooAlpha = GreenGooAlpha;
		OutMeltAlpha = AccMeltAlpha.Value;
		OutDissolveAlpha = DissolveAlpha;
	}

	///////////////////////////////////////////////////////////////////////////////////////////////////
	// @TODO: move these to SummitSettings. and review all AI, which need a new settings assets, etc. 

	UPROPERTY(Category = "Metal Melting")
	UNiagaraSystem VFX_MeltingAsset_StaticMesh;

	UPROPERTY(Category = "Metal Melting")
	UNiagaraSystem VFX_MeltingAsset_SkeletalMesh;

	UPROPERTY(Category = "Metal Melting")
	UNiagaraSystem VFX_MeltingFinishedAsset;

	// the material used to overlay the green go over the mesh, prior to Vertex offset melting taking place
	UPROPERTY(Category = "Metal Melting")
	UMaterialInterface OverlayMeltingMat;

	// remap of the MeltAlpha
	UPROPERTY(Category = "Metal Melting")
	FRuntimeFloatCurve GreenGoAlphaCurve;
	default GreenGoAlphaCurve.AddDefaultKey(0, 0.0);
	default GreenGoAlphaCurve.AddDefaultKey(0, 1.0);
	///////////////////////////////////////////////////////////////////////////////////////////////////

	void ProcessMetalHit(FHitResult Hit, FVector ProjectileDir)
	{
	}

}

namespace MeltDevToggles
{
	const FHazeDevToggleBool ShowMeltAlphas;
}
