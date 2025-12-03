
class USummitDecimatorSpikeBombSelfDetonateBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	AAISummitDecimatorSpikeBomb SpikeBomb;
	UBasicAIHealthComponent HealthComp;
	USummitDecimatorSpikeBombSettings Settings;
	USummitMeltComponent MeltComp;
	UHazeActorRespawnableComponent RespawnComp;
	USummitDecimatorSpikeBombAutoAimComponent AutoAimComp;
	USummitDecimatorShockwaveSpikeBombResponseComponent ShockwaveResponseComp;
	UHazeMovementComponent MoveComp;
	float DetonationTimer;
	bool bHasBeenHitByAutoAimRoll = false;
	bool bHasBeenHitByShockwave = false;
	bool bHasFallenOffStage = false;
	float HitByRollTime;

	UMaterialInstanceDynamic MaterialInstance;
	FLinearColor OriginalColor;
	FHazeAcceleratedVector AccCurrentColor;
	float BlinkTime = 0;
	float BlinkInterval = 0.5;
	
	float KillZ;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"Reset");
		AutoAimComp = USummitDecimatorSpikeBombAutoAimComponent::GetOrCreate(Owner);
		AutoAimComp.OnAutoAimAssistedHit.AddUFunction(this, n"OnAutoAimAssistedHit");
		AutoAimComp.OnManualAimHit.AddUFunction(this, n"OnManualAimHit");
		ShockwaveResponseComp = USummitDecimatorShockwaveSpikeBombResponseComponent::GetOrCreate(Owner);
		ShockwaveResponseComp.OnHitByShockwave.AddUFunction(this, n"OnHitByShockwave");
		MoveComp = UHazeMovementComponent::Get(Owner);
		Settings = USummitDecimatorSpikeBombSettings::GetSettings(Owner);
		SpikeBomb = Cast<AAISummitDecimatorSpikeBomb>(Owner);

		// Store reference to Decimator
		MeltComp = USummitMeltComponent::Get(Owner);
		DetonationTimer = Settings.SelfDetonationTime;

		UStaticMeshComponent CrystalMesh = Cast<AAISummitDecimatorSpikeBomb>(Owner).MeshCrystal;
		UMaterialInterface Material = CrystalMesh.Materials[0];

		MaterialInstance = Material::CreateDynamicMaterialInstance(this, Material);
		for (int i = 0; i < CrystalMesh.GetMaterials().Num(); i++)
		{
			CrystalMesh.SetMaterial(i, MaterialInstance);
		}

		if (MaterialInstance != nullptr)
		{
			OriginalColor = MaterialInstance.GetVectorParameterValue(n"EmissiveColor");
		}

		UHazeTeam DecimatorTeam = HazeTeam::GetTeam(DecimatorTopdownTags::DecimatorTeamTag);
		for (auto Member : DecimatorTeam.GetMembers())
		{
			if (Member == nullptr)
				continue;
			KillZ = Member.ActorLocation.Z - 1000;
		}		
	}

	UFUNCTION()
	private void OnManualAimHit()
	{
		HitByRollTime = Time::GetGameTimeSeconds();
	}

	UFUNCTION()
	private void OnHitByShockwave()
	{
		bHasBeenHitByShockwave = true;
	}

	UFUNCTION()
	private void OnAutoAimAssistedHit()
	{
		bHasBeenHitByAutoAimRoll = true;
		HitByRollTime = Time::GetGameTimeSeconds();
	}

	UFUNCTION()
	private void Reset()
	{
		DetonationTimer = Settings.SelfDetonationTime;
		BlinkTime = 0;
		BlinkInterval = 0.5;
		bHasBeenHitByAutoAimRoll = false;
		bHasBeenHitByShockwave = false;
		bHasFallenOffStage = false;
		HitByRollTime = BIG_NUMBER;
		AccCurrentColor.SnapTo(FVector(OriginalColor.R,OriginalColor.G,OriginalColor.B));
		auto Color = FLinearColor(AccCurrentColor.Value.X, AccCurrentColor.Value.Y, AccCurrentColor.Value.Z, 0);
		MaterialInstance.SetVectorParameterValue(n"EmissiveColor", Color);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		
		if (bHasFallenOffStage)
			return true;

		if (bHasBeenHitByShockwave)
			return true;
		
		if (Time::GetGameTimeSince(HitByRollTime) > 0.25 && (MoveComp.IsOnAnyGround() || MoveComp.HasWallContact()))
			return true;

		if (DetonationTimer > 0)
			return false;

		if (bHasBeenHitByAutoAimRoll && DetonationTimer > -Settings.SelfDetonationTime) // double timer after auto aim assist. Failsafe to destroy self even if fell out of arena or other unexpected behaviour.
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride, Meta = (NoSuperCall))
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		
		// Trigger effect
		if (MoveComp.IsOnAnyGround())
			USummitDecimatorSpikeBombEffectsHandler::Trigger_OnExplode(Owner);
		else
			USummitDecimatorSpikeBombEffectsHandler::Trigger_OnExplodeMidAir(Owner);

		// Spawn Explosion Trail and kill self
		SpikeBomb.OnSpikeBombExploded.Broadcast(Owner.ActorLocation);

		// Deal damage to nearby players
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (!Owner.ActorCenterLocation.IsWithinDist(Player.ActorCenterLocation, Settings.DetonationExplosionDamageRange)) 
				continue;

			Player.DealTypedDamage(Owner, Settings.DetonationExplosionPlayerDamage, EDamageEffectType::Explosion, EDeathEffectType::Explosion);
		}



#if EDITOR
		UHazeTeam DecimatorTeam = HazeTeam::GetTeam((DecimatorTopdownTags::DecimatorTeamTag));
		for (auto Member : DecimatorTeam.GetMembers())
		{
			if (Member == nullptr)
				continue;
			//Member.bHazeEditorOnlyDebugBool = true;
			if (Member != nullptr && Member.bHazeEditorOnlyDebugBool)
			{
				Debug::DrawDebugSphere(Owner.ActorCenterLocation, Settings.DetonationExplosionDamageRange, LineColor = FLinearColor::Red, Duration = 1.0);
			}
		}
#endif
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Reset();
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		// Failsafe for out of bounds.
		if (Owner.ActorLocation.Z < KillZ)
		{
			// Self destruct
			bHasFallenOffStage = true;
		}

		if(!MeltComp.bMelted)
			return;

		DetonationTimer -= DeltaTime;
		
		BlinkTime += DeltaTime;
		
		// Blinkinterval phases: keep original color -> turn into emissive red -> return to original
		if (BlinkTime > 3*BlinkInterval) // end of third phase, shorten interval time and return to first phase
		{
			BlinkTime -= 3*BlinkInterval;
			BlinkInterval *= 0.8;
			BlinkInterval = Math::Max(0.1, BlinkInterval);
		}
		else if (BlinkTime > 2*BlinkInterval) // third phase, turn back into original color
		{			
			AccCurrentColor.AccelerateTo(FVector(OriginalColor.R, OriginalColor.G, OriginalColor.B), BlinkInterval, DeltaTime);
			auto Color = FLinearColor(AccCurrentColor.Value.X, AccCurrentColor.Value.Y, AccCurrentColor.Value.Z, 0);
			MaterialInstance.SetVectorParameterValue(n"EmissiveColor", Color);
		}
		else if (BlinkTime > BlinkInterval) // second phase, turn into emissive red
		{
			AccCurrentColor.AccelerateTo(FVector(30, 0, 0) / (BlinkInterval * BlinkInterval),  BlinkInterval, DeltaTime); // increase intensity with shorter blink interval
			auto Color = FLinearColor(AccCurrentColor.Value.X, AccCurrentColor.Value.Y, AccCurrentColor.Value.Z, 0);
			MaterialInstance.SetVectorParameterValue(n"EmissiveColor", Color);
		}
		// else, first phase - keep original color for one interval.
	}

}