struct FTeenDragonPackedAcidHitEvents
{
	TArray<FVector> RelativeHitLocations;
	float TotalDamage;
	UAcidResponseComponent ResponseComp;
}

class UTeenDragonAcidSprayComponent : UActorComponent
{
	UPROPERTY(Category = "UI")
	TSubclassOf<UCrosshairWidget> AcidSprayCrosshair;

	UPROPERTY(Category = "UI")
	TSubclassOf<UCrosshairWidget> TopDownAcidSprayCrosshair;

	UPROPERTY(Category = "UI")
	TSubclassOf<ATeenDragonAcidSprayTopDownIndicator> TopDownAcidSprayDirectionIndicatorActorClass;

	UPROPERTY(Category = "Camera Shake")
	TSubclassOf<UCameraShakeBase> AcidSprayCameraShake;

	UPROPERTY(Category = "Settings")
	FAiming2DCrosshairSettings Crosshair2DSettings;

	UPROPERTY(Category = "Settings")
	UTeenDragonAcidSpraySettings AcidSpraySettings;

	UPROPERTY(Category = "Settings")
	UTeenDragonAcidSpraySettings TopDownAcidSpraySettings;

	UPROPERTY(Category = "Settings")
	UTeenDragonMovementSettings SprayMovementSettings;

	UPROPERTY(Category = "Settings")
	UHazeCameraSettingsDataAsset TriggerAimCameraSettings;

	UPROPERTY(Category = "Acid Spray")
	TSubclassOf<AAcidProjectile> ProjectileClass;

	UPROPERTY(Category = "Acid Spray")
	TSubclassOf<AAcidPuddle> PuddleClass;

	UPROPERTY(Category = "Acid Spray")
	TSubclassOf<AAcidPuddle> NewPuddleClass;

	// ----------------------------------------------------------------------------------------------------------------
	// @TODO: Move this to SummitMeltComp when we have time. We'll just copy over the assets for now

	UPROPERTY(Category = "Metal Melting")
	UNiagaraSystem VFX_MeltingAsset_StaticMesh;

	UPROPERTY(Category = "Metal Melting")
	UNiagaraSystem VFX_MeltingAsset_SkeletalMesh;

	UPROPERTY(Category = "Metal Melting")
	UNiagaraSystem VFX_MeltFinisher_SkeletalMesh;

	UPROPERTY(Category = "Metal Melting")
	UNiagaraSystem VFX_MeltFinisher_StaticMesh;

	// the material used to overlay the green go over the mesh, prior to Vertex offset melting taking place
	UPROPERTY(Category = "Metal Melting")
	UMaterialInterface OverlayMeltingMat;

	// remap of the MeltAlpha
	UPROPERTY(Category = "Metal Melting")
	FRuntimeFloatCurve GreenGoAlphaCurve;
	default GreenGoAlphaCurve.AddDefaultKey(0, 0.0);
	default GreenGoAlphaCurve.AddDefaultKey(0, 1.0);

	// ----------------------------------------------------------------------------------------------------------------

	UPROPERTY()
	bool bNewSpray = true;

	// DONT TOUCH UNLESS VFX :)
	UPROPERTY()
	float FireRatePerSec = 30;

	float RemainingAcidAlpha = 1.0;
	TInstigated<float> AcidSprayRangeMultiplier(1.0);
	TInstigated<float> AcidSprayStaminaMultiplier(1.0);
	TArray<FTeenDragonPackedAcidHitEvents> PackedAcidHits;

	private UPlayerAcidTeenDragonComponent DragonComp;
	UNiagaraComponent SprayEffect;
	UNiagaraComponent TopDownSprayEffect;

	private USceneComponent TopDownAcidSprayRoot;
	private USceneComponent AcidSprayRoot;

	// This component acts as a manager for the impact VFX atm.
	TMap<AHazeActor, FAcidImpactActorParams> AcidImpactParams;

	const float AcidHitSendRatePerSecond = 10.0;
	float StoredAcidHits = 0.0; 

	FHitResult PrevHitSentToNiagara;
	FVector PrevAnalyticalWallNormal = FVector::ZeroVector;
	void SendAnalyticalColllisionDataToNiagara(FHitResult InHit, FVector ProjectileVelocity)
	{
		FVector AnalyticalWallNormal = -ProjectileVelocity;
		if(AnalyticalWallNormal.Normalize() == false)
		{
			// if it fails for some reason then just use the direction to the dragon head 
			const FVector HeadLocation = TopDownSprayEffect.GetWorldLocation();
			AnalyticalWallNormal = (HeadLocation - InHit.ImpactPoint);
			AnalyticalWallNormal.Normalize();
		}

		// init the previous hit with current hit the first time it happens..
		if(PrevHitSentToNiagara.IsValidBlockingHit() == false)
		{
			PrevHitSentToNiagara = InHit;
			PrevAnalyticalWallNormal = AnalyticalWallNormal;
		}

		if(TopDownSprayEffect.IsActive())
		{
			TopDownSprayEffect.SetNiagaraVariablePosition("GP_LatestCollisionPos_2", PrevHitSentToNiagara.ImpactPoint);
			TopDownSprayEffect.SetNiagaraVariableVec3("GP_LatestCollisionNormal_2", PrevAnalyticalWallNormal);
			TopDownSprayEffect.SetNiagaraVariablePosition("GP_LatestCollisionPos_1", InHit.ImpactPoint);
			TopDownSprayEffect.SetNiagaraVariableVec3("GP_LatestCollisionNormal_1", AnalyticalWallNormal);
			TopDownSprayEffect.SetNiagaraVariableFloat("GP_LatestCollisionTimestamp", Time::GetGameTimeSeconds());
		}

		if(SprayEffect.IsActive())
		{
			SprayEffect.SetNiagaraVariablePosition("GP_LatestCollisionPos_2", PrevHitSentToNiagara.ImpactPoint);
			SprayEffect.SetNiagaraVariableVec3("GP_LatestCollisionNormal_2", PrevAnalyticalWallNormal);
			SprayEffect.SetNiagaraVariablePosition("GP_LatestCollisionPos_1", InHit.ImpactPoint);
			SprayEffect.SetNiagaraVariableVec3("GP_LatestCollisionNormal_1", AnalyticalWallNormal);
			SprayEffect.SetNiagaraVariableFloat("GP_LatestCollisionTimestamp", Time::GetGameTimeSeconds());
		}

		PrevHitSentToNiagara = InHit;
		PrevAnalyticalWallNormal = AnalyticalWallNormal;

		// Debug::DrawDebugArrow(
		// 	InHit.ImpactPoint,
		// 	InHit.ImpactPoint - AnalyticalWallNormal*1000.0,
		// 	100.0,
		// 	FLinearColor::Yellow,
		// 	10,
		// 	1.0
		// );
		// Debug::DrawDebugSphere(InHit.ImpactPoint, 100, 12, FLinearColor::Yellow, 3, 0.2);
		// Debug::DrawDebugArrow(
		// 	PrevHitSentToNiagara.ImpactPoint,
		// 	PrevHitSentToNiagara.ImpactPoint - PrevAnalyticalWallNormal*1000.0,
		// 	100.0,
		// 	FLinearColor::Red,
		// 	10,
		// 	1.0
		// );
	}

	void OnDragonSpawn(AHazePlayerCharacter Player, ATeenDragon Dragon)
	{
		DragonComp = UPlayerAcidTeenDragonComponent::Get(Player);

		TopDownAcidSprayRoot = USceneComponent::Create(Dragon, n"TopDownSprayRoot");
		
		TopDownSprayEffect = UNiagaraComponent::Get(Dragon, n"TopDownSprayEffect");
		TopDownSprayEffect.AttachToComponent(TopDownAcidSprayRoot, n"NAME_None", EAttachmentRule::KeepRelative);
		
		AcidSprayRoot = USceneComponent::Create(Dragon, n"SprayRoot");
		
		AcidSprayRoot.AttachToComponent(DragonComp.DragonMesh, AcidSpraySettings.ShootSocket);
		SprayEffect = UNiagaraComponent::Get(Dragon, n"SprayEffect");
		SprayEffect.AttachToComponent(AcidSprayRoot, n"NAME_None", EAttachmentRule::KeepRelative);

		ToggleSpray(false);

		Player.ApplyDefaultSettings(AcidSpraySettings);
	}
	
	void AlterAcidAlpha(float Amount)
	{
		RemainingAcidAlpha += Amount;
		RemainingAcidAlpha = Math::Clamp(RemainingAcidAlpha, 0.0, 1.0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TArray<FVector> Positions;
		auto Projectiles = Acid::GetAcidManager().Projectiles;
		for(int i = 0; i < Projectiles.Num(); i++)
		{
			auto Projectile = Projectiles[i];
			Positions.Add(Projectile.ActorLocation);
			TEMPORAL_LOG(Game::Mio, "Acid Spray Projectiles")
				.Sphere(f"Projectile {i}", Projectile.ActorLocation, 20, FLinearColor::Yellow)
			;
			// Debug::DrawDebugPoint(Projectile.ActorLocation, 10, FLinearColor::Yellow);
		}

		if(DragonComp.bTopDownMode)
		{
			PlaceTopDownAcidSprayRoot();
		}

		PackAcidHits();

		MeltEffectParams_Update(DeltaSeconds);

		StoredAcidHits += DeltaSeconds * AcidHitSendRatePerSecond;
		StoredAcidHits = Math::Clamp(StoredAcidHits, 0.0, 2.0);
		for(auto PackedHit : PackedAcidHits)
		{
			TEMPORAL_LOG(Owner, "Acid Spray")
				.Value(f"Number of hit locations {PackedHit.ResponseComp}", PackedHit.RelativeHitLocations.Num())
			;
		}
		TEMPORAL_LOG(Owner, "Acid Spray")	
			.Value("Stored Hits", StoredAcidHits)
			.Value("Acid Hit count", PackedAcidHits.Num())
		;
	}

	private void PackAcidHits()
	{
		if(HasControl())
		{
			if(PackedAcidHits.Num() > 0)
			{
				TArray<FTeenDragonPackedAcidHitEvents> ArrayToSend;
				TArray<FTeenDragonPackedAcidHitEvents> ArrayNotToSend;
				for(int i = 0; i < PackedAcidHits.Num(); ++i)
				{
					if(StoredAcidHits >= 1)
					{
						ArrayToSend.Add(PackedAcidHits[i]);
						StoredAcidHits--;
					}
					else
						ArrayNotToSend.Add(PackedAcidHits[i]);
				}
				if (ArrayToSend.Num() > 0)
					CrumbProcessAcidHitEvents(ArrayToSend);

				PackedAcidHits = ArrayNotToSend;
			}
		}
	}
	

	const float ProjectileSameHitDistThreshold = 50.0;
	void AddAcidHitEvent(UAcidResponseComponent ResponseComp, float Damage, FVector HitLocation)
	{
		bool bAlreadyExists = false;
		for(auto& PackedHit : PackedAcidHits)
		{
			if(PackedHit.ResponseComp != ResponseComp)
				continue;
			
			FVector NewRelativeLocation = HitLocation - ResponseComp.WorldLocation;
			// Disregard hit location if too close to another hit (to save space)
			int FoundIndex = -1;
			for(int i = 0; i < PackedHit.RelativeHitLocations.Num(); ++i)
			{
				float DistSqr = PackedHit.RelativeHitLocations[i].DistSquared(NewRelativeLocation);
				if(DistSqr < Math::Square(ProjectileSameHitDistThreshold))
				{
					FoundIndex = i;
					break;
				}
			}
			
			// No Location was too close, adding the location is fine
			if(FoundIndex == -1)
				PackedHit.RelativeHitLocations.Add(NewRelativeLocation);
			// Move location to new location so it follows the spray
			else
			{
				PackedHit.RelativeHitLocations[FoundIndex] = NewRelativeLocation;
				bAlreadyExists = true;
			}

			// Damage is divided on number of hit location so damage is still the same
			PackedHit.TotalDamage += Damage;
			return;
		}

		if(!bAlreadyExists)
		{
			FTeenDragonPackedAcidHitEvents NewEvent;
			NewEvent.ResponseComp = ResponseComp;
			NewEvent.TotalDamage = Damage;
			NewEvent.RelativeHitLocations.Add(HitLocation - ResponseComp.WorldLocation);
			PackedAcidHits.Add(NewEvent);
		}
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbProcessAcidHitEvents(TArray<FTeenDragonPackedAcidHitEvents> Events)
	{
		for(auto Event : Events)
		{
			for(auto RelativeHitLocation : Event.RelativeHitLocations)
			{
				FAcidHit NewHit;
				NewHit.Damage = Event.TotalDamage / Event.RelativeHitLocations.Num();
				NewHit.PlayerInstigator = Game::Mio;

				FHazeTraceSettings Trace;
				Trace.TraceWithChannel(ECollisionChannel::WeaponTracePlayer);
				Trace.UseLine();

				FTransform TargetSocket = DragonComp.DragonMesh.GetSocketTransform(AcidSpraySettings.ShootSocket);
				FVector TargetSocketOrigin = TargetSocket.TransformPosition(bNewSpray ? FVector(-20, 0, 0) : AcidSpraySettings.ShootSocketOffset);
				FVector HitLocation = Event.ResponseComp.WorldLocation + RelativeHitLocation;
				FVector TraceDir = (HitLocation -  TargetSocketOrigin).GetSafeNormal();


				// Trace from just outside the hit location to the hit location
				auto Hit = Trace.QueryTraceSingle(HitLocation - TraceDir * 5, HitLocation + TraceDir * 5);
				if(Hit.bBlockingHit)
				{
					NewHit.HitComponent = Hit.Component;
					NewHit.ImpactNormal = Hit.ImpactNormal;
					NewHit.ImpactLocation = Hit.ImpactPoint;
				}
				else
				{
					// TODO: This happens sometime, check if this is proper handling
					// I got it hitting the back side of the Ruby knights arm 
					NewHit.ImpactLocation = HitLocation;
					NewHit.ImpactNormal = -TraceDir;	
				}
				TEMPORAL_LOG(this)
					.HitResults("Acid Hit Retrace", Hit, FHazeTraceShape::MakeLine())
				;

				if (Event.ResponseComp.bIsPrimitiveParentExclusive)
				{
					if (NewHit.HitComponent == Event.ResponseComp.AttachParent)
						Event.ResponseComp.OnAcidHit.Broadcast(NewHit);
					return;	
				}

				Event.ResponseComp.OnAcidHit.Broadcast(NewHit);
			}
		}
	}

	private void PlaceTopDownAcidSprayRoot()
	{
		auto HeadTransform = DragonComp.DragonMesh.GetSocketTransform(AcidSpraySettings.ShootSocket);

		TopDownAcidSprayRoot.WorldLocation = HeadTransform.Location;

		FVector Up = HeadTransform.Rotation.UpVector;
		Up = Up.ConstrainToPlane(FVector::UpVector);

		TopDownAcidSprayRoot.WorldRotation = FRotator::MakeFromZ(Up);

		TEMPORAL_LOG(Owner, "AcidSpray")
			.DirectionalArrow("Root Forward", TopDownAcidSprayRoot.WorldLocation, TopDownAcidSprayRoot.ForwardVector * 500, 20, 40, FLinearColor::Red)
			.DirectionalArrow("Root Up", TopDownAcidSprayRoot.WorldLocation, TopDownAcidSprayRoot.UpVector * 500, 20, 40, FLinearColor::Blue)
			.DirectionalArrow("Root Right", TopDownAcidSprayRoot.WorldLocation, TopDownAcidSprayRoot.RightVector * 500, 20, 40, FLinearColor::Green)
		;
	}

	FTransform GetAcidSprayTransform() const property
	{
		if(DragonComp.bTopDownMode)
			return TopDownAcidSprayRoot.WorldTransform;
		else
			return AcidSprayRoot.WorldTransform;
	}

	void ToggleSpray(bool bToggleOn)
	{
		if(bToggleOn)
		{
			if(DragonComp.bTopDownMode)
				TopDownSprayEffect.Activate();
			else
				SprayEffect.Activate();
		}
		else
		{
			TopDownSprayEffect.Deactivate();
			SprayEffect.Deactivate();
		}
	}

	void ProcessMetalHit(FHitResult Hit, FVector ProjectileDir)
	{
		MeltEffectParams_Init(Hit, ProjectileDir);
	}

	float TimeStampLastMelt = -1.0;

	private const int MaxSpheresPerMesh = 8;
	// private const float DistanceOutSideSphereMaskForNewSphere = 50.0;
	private const float DistanceOutSideSphereMaskForNewSphere = 5000.0;
	void MeltEffectParams_Init(FHitResult Hit, FVector ProjectileDir)
	{
		auto MetalActor = Cast<AHazeActor>(Hit.Actor);
		
		if(MetalActor == nullptr)
			return;

		auto StaticMeshComp = Cast<UStaticMeshComponent>(Hit.Component);
		auto SkeletalMeshComp = Cast<UHazeSkeletalMeshComponentBase>(Hit.Component);

		// we only handle meshes in here.
		if(StaticMeshComp == nullptr && SkeletalMeshComp == nullptr)
			return;

		USummitMeltComponent MeltComp = USummitMeltComponent::Get(MetalActor);

		float MeltingSpeed = 0.0;
		float DissolvingSpeed = 0.0;

		auto NightQueenActor = Cast<ANightQueenMetal>(Hit.Actor);

		// if(NightQueenActor == nullptr && StaticMeshComp != nullptr)
		if(NightQueenActor == nullptr && MeltComp == nullptr)
		{
			// early out. we don't support melting this type of actor
			return;
		}

		if(StaticMeshComp != nullptr)
		{
			// make sure that we only allow StaticMeshes that are of the type summitMeltPartComponent
			auto MeltPartComp = Cast<USummitMeltPartComponent>(Hit.Component);
			if(NightQueenActor == nullptr && MeltPartComp == nullptr)
			{
				// devCheck(false);
				return;
			}
		}

		if(NightQueenActor != nullptr)
		{
			// handle early out when fully dissolved 
			bool bHandleRegrow = NightQueenActor.ShouldRegrow() || NightQueenActor.ShouldUnDissolve();
			bool bFullyDissolved = NightQueenActor.MeltedAlpha >= 1.0 && NightQueenActor.DissolveAlpha >= 1.0;
			if(bHandleRegrow || bFullyDissolved)
			{
				// no need to spawn new ones, the metal is dead.
				return;
			}

			auto NightQueenMeltSettings = UNightQueenMetalMeltingSettings::GetSettings(NightQueenActor);
			MeltingSpeed = NightQueenMeltSettings.MeltingSpeed;
			DissolvingSpeed = NightQueenMeltSettings.DissolvingSpeed;
		}
		else
		{
			if(MeltComp.bMelted || MeltComp.DissolveAlpha > 0.0 || MeltComp.bDissolved)
			{
				// early out until it has regenerated
				return;
			}

			if(MeltComp != nullptr)
			{
				// They are using durations. Which is good. But maybe we should rewrite this
				// to use durations instead first. 
				DissolvingSpeed = MeltComp.Settings.SphereMask_DissolvingSpeed;
				MeltingSpeed = MeltComp.Settings.SphereMask_MeltingSpeed;
			}
			else
			{
				// @TODO: to support more classes
				devCheck(false);
				return;
			}
		}
		
		UMeshComponent MeshComp = nullptr;
		FVector RelativeLocation = FVector::ZeroVector;
		FName BoneName = NAME_None;

		if(StaticMeshComp != nullptr)
		{
			RelativeLocation = StaticMeshComp.WorldTransform.InverseTransformPosition(Hit.ImpactPoint);
			MeshComp = StaticMeshComp;
		}
		else if(SkeletalMeshComp != nullptr)
		{
			RelativeLocation = SkeletalMeshComp.GetBoneTransform(Hit.BoneName).InverseTransformPosition(Hit.ImpactPoint);
			MeshComp = SkeletalMeshComp;
			BoneName = Hit.BoneName;
		}

	 	// taken from melting comp
		// const float BumpValue = 1.0 / 50.0;
		const float MaxRad = Hit.Component.GetBoundsRadius() * 2.0;
		// const float IncrementPerHit = MaxRad * BumpValue;

		bool bContainsActor = AcidImpactParams.Contains(MetalActor);

		if(bContainsActor)
		{
			auto& ActorParams = AcidImpactParams[MetalActor];

			ActorParams.TimeStampLastMeltHit = Time::GetGameTimeSeconds();

			if(MeltComp != nullptr && MeltComp.Settings.MinHealth > 0.0)
			{
				auto& FirstCompParam = ActorParams.ComponentParams[0];
				ActorParams.ComponentParams[0].RelativeLocation = RelativeLocation;
				ActorParams.ComponentParams[0].MeshRelativeTo = MeshComp;
				ActorParams.ComponentParams[0].BoneName = BoneName;

				// PrintToScreen("Init. RelativeLoc: " + RelativeLocation, 0.5);
				// devCheck(RelativeLocation.Equals(ActorParams.ComponentParams[0].RelativeLocation));
				// Debug::DrawDebugPoint(Hit.ImpactPoint, 60.0, FLinearColor::Blue, 0.2);
			}

			// ugly hack to compensate for us not updating the sphere locations every hit. 
			// since that would mess with the logic applied in niagara atm.
			// for now we'll just send the latest world location to try this out.
			// but ideally we should be moving around the latest (and last) sphere instead
			// and use that data to infer where the latest impact location is
			if(ActorParams.EffectComponent != nullptr)
			{
				ActorParams.EffectComponent.SetNiagaraVariablePosition("LatestDissolveImpactPosition", Hit.ImpactPoint);
			}

			// Has too many sphere masks already
			if(ActorParams.ComponentParams.Num() == 8)
				return;

			for(auto& CompParams : ActorParams.ComponentParams)
			{
				float DistSqrd = RelativeLocation.DistSquared(CompParams.RelativeLocation);

				float MinDistanceSqrd = Math::Square(CompParams.AccSphereMaskRadius.Value + DistanceOutSideSphereMaskForNewSphere);
				// Too close to previous sphere don't make new sphere
				if(DistSqrd < MinDistanceSqrd)
				{
					// bump up the melt speed like those actors do if it isn't queen metal
					if(NightQueenActor == nullptr)
					{
						// SphereMask.MeltMaxRadius += IncrementPerHit;
						// SphereMask.MeltMaxRadius = Math::Clamp(SphereMask.MeltMaxRadius, 0.0, MaxRad);
					}
					return;
				}
			}

		}

		FAcidImpactComponentParams NewComponentParams;
		NewComponentParams.NormalizedImpactVelocity = ProjectileDir;
		NewComponentParams.DissolveDuration = 1 / DissolvingSpeed;

		NewComponentParams.ExpansionDuration = 1 / MeltingSpeed;
		// NewSphereMask.MeltMaxRadius = IncrementPerHit;
		NewComponentParams.MaxExpansionRadius = MaxRad;
		NewComponentParams.AccSphereMaskRadius.SnapTo(0.0);

		NewComponentParams.RelativeLocation = RelativeLocation;
		NewComponentParams.MeshRelativeTo = MeshComp;
		NewComponentParams.BoneName = BoneName;

		if(bContainsActor)
		{
			AcidImpactParams[MetalActor].ComponentParams.Add(NewComponentParams);

			// Print("Adding Effect Param For SAME Actor");
		}
		else
		{
			// New Actor.

			UNiagaraComponent MeltEffectComp = nullptr;
			if(SkeletalMeshComp != nullptr)
			{
				if(MeltComp != nullptr && MeltComp.Settings.OverrideImpactVFXAsset_SkelMesh != nullptr)
				{
					MeltEffectComp = Niagara::SpawnLoopingNiagaraSystemAttached(
						MeltComp.Settings.OverrideImpactVFXAsset_SkelMesh,
						MeshComp, 
						BoneName
					);
				}
				else
				{
					MeltEffectComp = Niagara::SpawnLoopingNiagaraSystemAttached(VFX_MeltingAsset_SkeletalMesh, MeshComp, BoneName);
				}
			}
			// Static mesh
			else
			{
				auto MeltAssetForStaticMesh = VFX_MeltingAsset_StaticMesh;

				if(NightQueenActor != nullptr && NightQueenActor.CurrentSettings.VFXOverride_Melting != nullptr)
				{
					MeltAssetForStaticMesh = NightQueenActor.CurrentSettings.VFXOverride_Melting;
				}

				if(MeltComp != nullptr && MeltComp.Settings.OverrideImpactVFXAsset_StaticMesh != nullptr)
				{
					MeltAssetForStaticMesh = MeltComp.Settings.OverrideImpactVFXAsset_StaticMesh;
				}

				// MeltEffectComp = Niagara::SpawnOneShotNiagaraSystemAttached(VFX_MeltingAsset_StaticMesh, MeshComp, BoneName);

				MeltEffectComp = Niagara::SpawnLoopingNiagaraSystemAttached(MeltAssetForStaticMesh, MeshComp, BoneName);
			}

			MeltEffectComp.SetWorldLocation(NewComponentParams.GetWorldLocation());

			if(OverlayMeltingMat != nullptr)
			{
				TArray<UMeshComponent> Meshes;
				MetalActor.GetComponentsByClass(UMeshComponent, Meshes);
				for(auto IterMesh : Meshes)
				{
					if (IterMesh.HasTag(n"SkipAcidOverlayMaterial"))
						continue;
					auto DynMat = Material::CreateDynamicMaterialInstance(IterMesh, OverlayMeltingMat);
					IterMesh.SetOverlayMaterial(DynMat);
				}
			}

			FAcidImpactActorParams NewActorParams;
			NewActorParams.bUpdateOverlay = OverlayMeltingMat != nullptr;
			NewActorParams.EffectComponent = MeltEffectComp;
			NewActorParams.bNightQueenMetal = NightQueenActor != nullptr;

			NewActorParams.ComponentParams.Add(NewComponentParams);

			// temp/hack. we should be moving the last sphere around and infer this location from that
			NewActorParams.EffectComponent.SetNiagaraVariablePosition("LatestDissolveImpactPosition", Hit.ImpactPoint);

			//NewActorParams.EffectComponent.DeactivateImmediate();
			//NewActorParams.EffectComponent.DestroyComponent(this);

			AcidImpactParams.Add(MetalActor, NewActorParams);

			// Print("Adding Effect Param For new Actor", 1.0);
		}
	}

	void MeltEffectParams_Update(float DeltaTime)
	{
		TArray<AHazeActor> MetalActorsToRemove;

		for(auto& EffectParams : AcidImpactParams)
		{
			auto& ActorParams = EffectParams.Value;

			auto MetalActor = EffectParams.Key;

			ANightQueenMetal NightQueenMetal = Cast<ANightQueenMetal>(MetalActor);
			USummitMeltComponent MeltComp = USummitMeltComponent::Get(MetalActor);

			if(MeltComp == nullptr && NightQueenMetal == nullptr)
			{
				// early out for the things we haven't accounted for now.
				return;
			}

			bool bNightQueenMetal = NightQueenMetal != nullptr;

			// Get the melt alpha
			float MeltAlpha = 0.0;
			if(bNightQueenMetal)
			{
				MeltAlpha = NightQueenMetal.MeltedAlpha;
			}
			else
			{
				MeltAlpha = MeltComp.GetMeltAlpha();
			}

			// Calculate GreenGooAlpha.
			// Bend the 0 to 1 melta alpha into a bell curve (ish), 
			// So Alpha = 1 becomes 0 at the end.
			float GreenGooAlpha = GreenGoAlphaCurve.GetFloatValue(MeltAlpha);

			// TEMP. Write the greenGoo alpha to Actors/Components, allowing other systems to read it.
			if(bNightQueenMetal)
			{
				// for now; save the alpha value on the Metal as well for EventHandlers to read from
				NightQueenMetal.GreenGoAlpha = GreenGooAlpha;
			}
			else
			{
				// keep a reference to the green go alpha on the melt comp as well for EBPs to read from
				// @TODO: This will become a problems since we need a melt component per mesh
				if(MeltComp != nullptr)
				{
					// PrintToScreen("GreenGoo alpha: " + GreenGooAlpha);
					// PrintToScreen("MeltaAlpha alpha: " + MeltAlpha);
					MeltComp.GreenGooAlpha = GreenGooAlpha;
				}
			}

			// Update the mask depending on what it is.
			if(bNightQueenMetal)
			{
				// the expansion of this one is based on a SPEED
				ActorParams.UpdateSphereMasks(DeltaTime);
			}
			else
			{
				// The expansion of this SphereMask is based on Amount_Of_Hits taken 
				ActorParams.UpdateSphereMasks(DeltaTime, MeltAlpha);
			}

			// update visuals

			bool bRubyHack = MeltComp != nullptr && (MeltComp.Settings.MinHealth > 0.0);
			if(bRubyHack)
			{
				// no overlay for ruby knight
				//ActorParams.UpdateComponentOverlayMaterial(Math::Max(Math::Pow(GreenGooAlpha * 0.5, 0.5), 0.1));
				ActorParams.SendDataToNiagara(DeltaTime, true);
			}
			else
			{
				ActorParams.UpdateComponentOverlayMaterial(GreenGooAlpha);
				ActorParams.SendDataToNiagara(DeltaTime, false);
			}

			// if(bNightQueenMetal)
			// 	PrintToScreen("DissolveAlpha: " + NightQueenMetal.DissolveAlpha);
			// PrintToScreen("MeltAlpha: " + MeltAlpha);
			// PrintToScreen("GreenGo: " + GreenGooAlpha);
			// PrintToScreen("NumSpheres: " + ActorParams.ComponentParams.Num());
			// PrintToScreen("" + MetalActor.GetName(), 0.0, FLinearColor::Yellow);
			// PrintToScreen("\n");

			// check if the stuff we are melting suddenly became hidden.
			bool bIsMetalActorHidden = MetalActor.IsHidden();
			// only valid if all registered components (for the actor that we are melting) are hidden
			bool bIsComponentHidden = true;
			for(int i = 0; i < ActorParams.ComponentParams.Num(); ++i)
			{
				if(ActorParams.ComponentParams[i].MeshRelativeTo.IsHiddenInGame() == false)
				{
					bIsComponentHidden = false;
					continue;
				}
			}
			bool bInvisibleMetal = bIsComponentHidden || bIsMetalActorHidden;

			// find unused spheres that need to be removed
			if(bNightQueenMetal)
			{
				// handle gameplay ctrl-z
				bool bHandleRegrow = NightQueenMetal.ShouldRegrow() || NightQueenMetal.ShouldUnDissolve();
				bool bDissolving = NightQueenMetal.MeltedAlpha >= 1.0 && NightQueenMetal.DissolveAlpha > 0.0;
				bool bFullyDissolved = NightQueenMetal.MeltedAlpha >= 1.0 && NightQueenMetal.DissolveAlpha >= 0.5;

				//PrintToScreenScaled("DissolveAlpha: " + NightQueenMetal.DissolveAlpha);

				if(bHandleRegrow)
				{
					ActorParams.ComponentParams.Empty();
				}

				if(bFullyDissolved)
				{
					// remove the sphere once melthing phase is over and dissolve has taken over
					MetalActorsToRemove.Add(NightQueenMetal);
					ActorParams.bSpawnFinisherVFX = true;
				}
			}
			// else if(MeltAlpha >= 1.0 || MeltAlpha <= 0.0)
			// else if(MeltComp.bMelted && MeltComp.bDissolved)
			else if(MeltComp.bMelted || MeltComp.bDissolved)
			{
				// this one is WIP. Ideally we want to do this when 
				// both bMelted and bDissolved is true, but animation
				// has hooked up their changes on bMelted only 
				// making the timing wrong for VFX. For now we'll 
				// just do the same as animation.
				MetalActorsToRemove.Add(MetalActor);
			}
			else if(MeltComp != nullptr && bInvisibleMetal)
			{
				//Print("Removal due to Invisible metal", 2.0, FLinearColor::Red);
				MetalActorsToRemove.Add(MetalActor);
			}

			// Fixes for stuff that doesn't melt or dissolve..
			if(	MeltComp != nullptr
			&&	MeltComp.Settings.MinHealth > 0.0 
			&&	MeltComp.MeltAlpha <= 0.0
			&&	MeltComp.HasFullHealth()
			&&	MeltComp.GetTimeSinceLastMelt() > 0.2 
			)
			{
				bool bAllSphereMasksAreNearlyZero = true;
				for(const auto& IterCompParams : ActorParams.ComponentParams)
				{
					if(IterCompParams.AccSphereMaskRadius.Value > 0.01)
					{
						bAllSphereMasksAreNearlyZero = false;
						break;
					}
				}

				if(bAllSphereMasksAreNearlyZero)
				{
					MetalActorsToRemove.Add(MetalActor);
					ActorParams.bSpawnFinisherVFX = false;
				}
			}

		}

		// remove unused ones
		for(auto Metal : MetalActorsToRemove)
		{
			auto& ActorParams = AcidImpactParams[Metal];

			if(ActorParams.EffectComponent != nullptr)
			{
				ActorParams.EffectComponent.Deactivate();
				ActorParams.CleanupOverlayMaterial();
			}

			// handle, setting based, vfx asset override
			auto StaticMeshFinisher = VFX_MeltFinisher_StaticMesh;
			ANightQueenMetal NightQueenMetal = Cast<ANightQueenMetal>(Metal);
			if(NightQueenMetal != nullptr)
			{
				if(NightQueenMetal.CurrentSettings.VFXOverride_MeltFinisher != nullptr)
				{
					StaticMeshFinisher = NightQueenMetal.CurrentSettings.VFXOverride_MeltFinisher;
				}
				
				if(NightQueenMetal.CurrentSettings.bDisableFinisher)
				{
					StaticMeshFinisher = nullptr;
				}
			}

			ActorParams.SpawnMeltFinisher(StaticMeshFinisher, VFX_MeltFinisher_SkeletalMesh);

			AcidImpactParams.Remove(Metal);
			// Print("DeactivateComp");
			// PrintToScreen("Removing: + " + Metal);
		}

		//PrintToScreenScaled("Num active melt params: " + AcidImpactParams.Num());

	}

};
