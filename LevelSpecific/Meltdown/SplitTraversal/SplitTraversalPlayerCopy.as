
class ASplitTraversalPlayerCopy : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase Mesh;
	default Mesh.ShadowPriority = EShadowPriority::Player;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilityClasses.Add(USplitTraversalCopyPartsCapability);

	UPROPERTY(DefaultComponent)
	UHazeTEMPCableComponent CopyGrapple;
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent CopyHookMesh;

	UPROPERTY(DefaultComponent)
	UDecalComponent ShadowDecal;

	UPROPERTY()
	TSubclassOf<AHazeActor> ShieldHoverboard;
	UPROPERTY()
	UNiagaraSystem SwingRopeNiagaraSystem;
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> DeathCameraShake;
	UPROPERTY(EditDefaultsOnly)
	UPlayerHighlightSettings CopyHighlightSettings;

	AHazePlayerCharacter CopyPlayer;
	ASplitTraversalManager Manager;

	default PrimaryActorTick.TickGroup = ETickingGroup::TG_PostPhysics;

	UHazePlayerVariantAsset ActiveVariant;
	UPlayerHealthComponent HealthComp;
	UPlayerSwingComponent SwingComp;
	UPlayerGrappleComponent GrappleComp;
	UPlayerBlobShadowSettings ShadowSettings;

	UNiagaraComponent VisualRopeInstance;
	AHazeActor DuplicatedHoverboard;
	bool bIsDead = false;
	bool bRopeRetracted = false;
	FTimerHandle RetractRopeTimerHandle;
	UMaterialInstanceDynamic ShadowDecalMaterial;

	float CurrentShadowOpacity;
	float CurrentShadowSize;

	APlayerHighlight Highlight;

	UPostProcessingComponent BushWobbleComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CopyGrapple.bSimulatePhysics = false;
		CopyGrapple.SetAbsolute(true, true, true);
		CopyGrapple.SetHiddenInGame(true);

		CopyHookMesh.SetAbsolute(true, true, true);
		CopyHookMesh.SetHiddenInGame(true);

		ShadowDecal.SetAbsolute(true, true, true);
		ShadowDecal.SetHiddenInGame(true);
		ShadowDecalMaterial = ShadowDecal.CreateDynamicMaterialInstance();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		BushWobbleComp.bOverridePlayerPosition = false;
	}

	void Init(AHazePlayerCharacter Player)
	{
		CopyPlayer = Player;
		HealthComp = UPlayerHealthComponent::Get(Player);
		SwingComp = UPlayerSwingComponent::Get(Player);
		GrappleComp = UPlayerGrappleComponent::Get(Player);
		BushWobbleComp = UPostProcessingComponent::Get(Player);
		BushWobbleComp.bOverridePlayerPosition = true;
		Mesh.SkeletalMeshAsset = CopyPlayer.Mesh.GetSkeletalMeshAsset();
		Mesh.SetLeaderPoseComponent(CopyPlayer.Mesh);
		ShadowSettings = UPlayerBlobShadowSettings::GetSettings(Player);

		HealthComp.OnDeathTriggered.AddUFunction(this, n"OnDeathTriggered");

		EffectEvent::LinkActorToReceiveEffectEventsFrom(this, CopyPlayer);
	}

	UFUNCTION(BlueprintPure)
	AHazePlayerCharacter GetCopyPlayer()
	{
		return CopyPlayer;
	}

	void SetPlayerVariant(UHazePlayerVariantAsset Variant)
	{
		ActiveVariant = Variant;
		if (CopyPlayer.IsMio())
			Mesh.SkeletalMeshAsset = Variant.MioSkeletalMesh;
		else
			Mesh.SkeletalMeshAsset = Variant.ZoeSkeletalMesh;
	}

	UFUNCTION(BlueprintPure)
	FTransform ApplyOffsetTransform(FTransform Transform)
	{
		FTransform Result = Transform;
		if (Manager.bBothPlayersInScifiWorld)
		{
			Result.AddToTranslation(FVector(-500000.0, 0.0, 0.0));
		}
		else
		{
			if (CopyPlayer.IsMio())
				Result.AddToTranslation(FVector(-500000.0, 0.0, 0.0));
			else
				Result.AddToTranslation(FVector(500000.0, 0.0, 0.0));
		}

		return Result;
	}

	UFUNCTION(BlueprintPure)
	FVector ApplyOffsetLocation(FVector Location)
	{
		if (Manager.bBothPlayersInScifiWorld)
		{
			return Location + FVector(-500000.0, 0.0, 0.0);
		}
		else
		{
			if (CopyPlayer.IsMio())
				return Location + FVector(-500000.0, 0.0, 0.0);
			else
				return Location + FVector(500000.0, 0.0, 0.0);
		}
	}

	UFUNCTION()
	void UpdatePlayerCopyPosition()
	{
		SetActorTransform(ApplyOffsetTransform(CopyPlayer.ActorTransform));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Manager == nullptr)
			Manager = ASplitTraversalManager::GetSplitTraversalManager();
		if (Manager == nullptr)
			return;

		UpdatePlayerCopyPosition();

		if (CopyPlayer.IsHidden())
			SetActorHiddenInGame(true);
		else
			SetActorHiddenInGame(false);

		ReplicateHoverboard();
		ReplicateDeathAndRespawnEffects();
		ReplicateGrappleRope();
		ReplicateShadowDecal(DeltaSeconds);
		ReplicatePlayerHighlight(DeltaSeconds);

		if(BushWobbleComp.Owner == Game::Mio || Manager.bBothPlayersInScifiWorld)
		{
			BushWobbleComp.OverridePlayerPosition = this.GetActorLocation();
			BushWobbleComp.OverridePlayerVelocity = CopyPlayer.GetActorVelocity();
		}
		else
		{
			BushWobbleComp.OverridePlayerPosition = CopyPlayer.GetActorLocation();
			BushWobbleComp.OverridePlayerVelocity = CopyPlayer.GetActorVelocity();
		}
	}

	void ReplicateHoverboard()
	{
		if (!CopyPlayer.IsAnyCapabilityActive(n"BattlefieldHoverboard") || CopyPlayer.IsCapabilityTagBlocked(n"Visibility"))
		{
			if (IsValid(DuplicatedHoverboard))
			{
				DuplicatedHoverboard.AddActorCollisionBlock(this);
				DuplicatedHoverboard.AddActorVisualsBlock(this);
			}
		}
		else
		{
			if (!IsValid(DuplicatedHoverboard))
			{
				DuplicatedHoverboard = SpawnActor(ShieldHoverboard);
				DuplicatedHoverboard.AttachToComponent(Mesh, n"LeftHand_IK");
			}

			DuplicatedHoverboard.RemoveActorCollisionBlock(this);
			DuplicatedHoverboard.RemoveActorVisualsBlock(this);
		}
	}

	UFUNCTION()
	private void OnDeathTriggered()
	{
		if (!bIsDead)
		{
			USplitTraversalPlayerCopyEventHandler::Trigger_PlayerDied(
				this, 
				FSplitTraversalPlayerCopyEffectParams(UDeathRespawnEffectSettings::GetSettings(CopyPlayer), 
				UPlayerHealthComponent::Get(CopyPlayer).GetSavedDeathDamageParams(),
				this));

			FPlayerDeathDamageParams ParamsTest = UPlayerHealthComponent::Get(CopyPlayer).GetSavedDeathDamageParams();
			Print(f"{ParamsTest.ForceScale=}");
			Print(f"{ParamsTest.ImpactDirection=}");
			Print(f"{ParamsTest.bIsFallingDeath=}");

			UDeathRespawnEffectSettings DeathRespawn = UDeathRespawnEffectSettings::GetSettings(CopyPlayer);
			Print(f"{DeathRespawn.ParticleForceMultiplier=}");

			bIsDead = true;

			if (CopyPlayer.IsZoe() && Manager.bSplitSlideActive)
			{
				// During split slide, Zoe dying plays a camera shake on Mio,
				// because Mio's camera location is the one used for both views
				Game::Mio.PlayCameraShake(DeathCameraShake, this);
			}
		}
	}

	void ReplicateDeathAndRespawnEffects()
	{
		const bool bPlayerDead = CopyPlayer.IsPlayerDead();
		if (bPlayerDead)
		{
			// if (!bIsDead)
			// {
			// 	USplitTraversalPlayerCopyEventHandler::Trigger_PlayerDied(
			// 		this, 
			// 		FSplitTraversalPlayerCopyEffectParams(UDeathRespawnEffectSettings::GetSettings(CopyPlayer), 
			// 		UPlayerHealthComponent::Get(CopyPlayer).GetSavedDeathDamageParams(),
			// 		this));

			// 	bIsDead = true;

			// 	if (CopyPlayer.IsZoe() && Manager.bSplitSlideActive)
			// 	{
			// 		// During split slide, Zoe dying plays a camera shake on Mio,
			// 		// because Mio's camera location is the one used for both views
			// 		Game::Mio.PlayCameraShake(DeathCameraShake, this);
			// 	}
			// }
		}
		else
		{
			bIsDead = false;
		}
	}

	void ReplicateSwingRope()
	{
		if (SwingComp == nullptr)
			return;

		if (SwingComp.Data.ActiveSwingPoint != nullptr)
		{
			// destroy the previous instance if it hasn't already
			if (bRopeRetracted)
			{
				if (VisualRopeInstance != nullptr)
				{
					VisualRopeInstance.DeactivateImmediate();
					VisualRopeInstance.DestroyComponent(this);
					VisualRopeInstance = nullptr;
				}

				// clear any previous handles since we can guarantee that any previous niagara comp is deactivated.
				RetractRopeTimerHandle.ClearTimerAndInvalidateHandle();
				bRopeRetracted = false;
			}
			
			if (VisualRopeInstance == nullptr)
			{
				auto Settings = UPlayerSwingSettings::GetSettings(CopyPlayer);

				VisualRopeInstance = Niagara::SpawnLoopingNiagaraSystemAttached(
					SwingComp.VisualRopeAsset,
					RootComponent, n"Hips");
				VisualRopeInstance.SetNiagaraVariableFloat("ExtendRopeDuration", Settings.ExtendRopeDuration);
				VisualRopeInstance.SetNiagaraVariableFloat("RetractRopeDuration", Settings.RetractRopeDuration);

				VisualRopeInstance.SetTickGroup(ETickingGroup::TG_LastDemotable);
				VisualRopeInstance.SetAutoDestroy(true);
				VisualRopeInstance.TickBehavior = ENiagaraTickBehavior::UseComponentTickGroup;
			}

			// we will draw the rope between 4 points; SwingPoint, both Hands and hip.
			FVector HandRight = Mesh.GetSocketLocation(n"RightAttach");
			FVector HandLeft = Mesh.GetSocketLocation(n"LeftAttach");
			FVector Hips = Mesh.GetSocketLocation(n"Hips");

			// need to handle cases when the hands are blocked.
			const bool bLeftBlocked = SwingComp.IsLeftHandBlocked();
			const bool bRightBlocked = SwingComp.IsRightHandBlocked();
			if(bLeftBlocked && bRightBlocked)
			{
				HandLeft = Hips;
				HandRight = Hips;
			}
			else if(bLeftBlocked || bRightBlocked)
			{
				if(bLeftBlocked)
				{
					HandLeft = HandRight;
				}
				else
				{
					HandRight = HandLeft;
				}
			}

			// For this to work, without the rope lagging behind, this function, UpdateRopeVisuals(), needs to be executed 
			// in a tickgroup that is before the NiagaraComponent instance tickgroup.  For example: 
			// UpdateRopeVisuals() in ::PostWork and have the component tick in ::LastDemotable.
			// And also make sure that the niagara system itself is forced to tick 
			// in the same tickgroup as the Niagaracomponent.
			const FVector FinalSwingPointLocation = SwingComp.Data.ActiveSwingPoint.GetWorldLocation() + SwingComp.Data.RopeOffset;
			VisualRopeInstance.SetNiagaraVariablePosition("WorldSwingPos", ApplyOffsetLocation(FinalSwingPointLocation));
			// Debug::DrawDebugPoint(FinalSwingPointLocation, 10.0, FLinearColor::Red);

			// change rope visuals based on variant type
			EHazePlayerVariantType CurrentVariantType;
			if (Manager.bBothPlayersInScifiWorld || CopyPlayer.IsMio())
				CurrentVariantType = EHazePlayerVariantType::Fantasy;
			else
				CurrentVariantType = EHazePlayerVariantType::Scifi;

			VisualRopeInstance.SetNiagaraVariableBool("UseScifiRope", CurrentVariantType != EHazePlayerVariantType::Fantasy);
			VisualRopeInstance.SetNiagaraVariableBool("UseFantasyRope", CurrentVariantType == EHazePlayerVariantType::Fantasy);

			// these positions need to be local to the Niagara system for them not to lag behind when swinging
			const FTransform NiagaraTransform = VisualRopeInstance.WorldTransform;

			TArray<FVector> AttachmentPoints;
			AttachmentPoints.Reserve(4);

			// we add a zero here for convenience sake. Rebuilding an array in niagara is not straight forward.
			// this makes it easier for us to replace the 0th index with the swingpoint location instead, in niagara.
			AttachmentPoints.Add(FVector::ZeroVector);

			AttachmentPoints.Add(NiagaraTransform.InverseTransformPosition(HandLeft));
			AttachmentPoints.Add(NiagaraTransform.InverseTransformPosition(HandRight));
			AttachmentPoints.Add(NiagaraTransform.InverseTransformPosition(Hips));

			NiagaraDataInterfaceArray::SetNiagaraArrayVector(VisualRopeInstance, n"AttachmentPoints", AttachmentPoints);
		}
		else
		{
			if (VisualRopeInstance != nullptr)
			{
				if (!bRopeRetracted)
				{
					bRopeRetracted = true;

					// flag niagara that it should retract the rope.
					VisualRopeInstance.SetVariableBool(n"RetractRope", true);
					VisualRopeInstance.SetVariableFloat(n"RetractTimeStamp", Time::GetGameTimeSeconds());

					// have the niagara comp deactivate slightly after it has retracted. Currently set to 0.5 in niagara.
					RetractRopeTimerHandle.ClearTimerAndInvalidateHandle();
					RetractRopeTimerHandle = Timer::SetTimer(this, n"HandleRopeRetracted", 0.6);
				}
			}
		}
	}

	UFUNCTION()
	private void HandleRopeRetracted()
	{
		if(VisualRopeInstance != nullptr)
		{
			// this will deactivate the visuals immediately, as long as the elapsed activation time > Particle.lifetime.
			VisualRopeInstance.Deactivate();
		}
	}

	void ReplicateGrappleRope()
	{
		if (GrappleComp == nullptr)
			return;

		AGrappleHook RealHook = GrappleComp.Grapple;

		TArray<FVector> Locations;
		RealHook.Cable.GetCableParticleLocations(Locations);

		for (FVector& Location : Locations)
			Location = ApplyOffsetLocation(Location);

		if (Manager.bBothPlayersInScifiWorld || CopyPlayer.IsMio())
			CopyGrapple.SetMaterial(0, RealHook.MAT_Fantasy);
		else
			CopyGrapple.SetMaterial(0, RealHook.MAT_Scifi);

		CopyGrapple.SetHiddenInGame(RealHook.IsHidden());
		CopyGrapple.SetWorldTransform(ApplyOffsetTransform(RealHook.ActorTransform));
		CopyGrapple.SetParticlesFromLocations(Locations);

		CopyHookMesh.SetHiddenInGame(RealHook.IsHidden());
		CopyHookMesh.SetStaticMesh(RealHook.HookMesh.StaticMesh);
		CopyHookMesh.SetWorldTransform(ApplyOffsetTransform(RealHook.HookMesh.WorldTransform));
	}

	void ReplicateShadowDecal(float DeltaTime)
	{
		FHazeTraceSettings Trace;
		Trace.TraceWithPlayer(CopyPlayer);
		Trace.UseLine();

		auto GroundHit = Trace.QueryTraceSingle(
			Mesh.WorldLocation + CopyPlayer.MovementWorldUp * 50.0,
			Mesh.WorldLocation + CopyPlayer.MovementWorldUp * -2000.0,
		);

		float TargetOpacity = CurrentShadowOpacity;
		if (GroundHit.bBlockingHit)
		{
			float Distance = Math::Abs((GroundHit.ImpactPoint - Mesh.WorldLocation).DotProduct(CopyPlayer.MovementWorldUp));
			TargetOpacity = ShadowSettings.OpacityCurve.GetFloatValue(Distance);
			CurrentShadowSize = ShadowSettings.SizeCurve.GetFloatValue(Distance) * 0.15;

		}
		else
		{
			TargetOpacity = 0;
			ShadowDecal.SetHiddenInGame(true);
		}

		CurrentShadowOpacity = Math::FInterpConstantTo(
			CurrentShadowOpacity, TargetOpacity,
			DeltaTime, 2.0
		);

		if (CurrentShadowOpacity >= 0.01)
		{
			ShadowDecal.SetHiddenInGame(false);
			ShadowDecal.SetWorldTransform(
				FTransform(
					FQuat::MakeFromX(CopyPlayer.MovementWorldUp),
					GroundHit.ImpactPoint,
					FVector(CurrentShadowSize, CurrentShadowSize, CurrentShadowSize),
				)
			);

			ShadowDecalMaterial.SetScalarParameterValue(n"Decal_Opacity", CurrentShadowOpacity);
		}
		else
		{
			ShadowDecal.SetHiddenInGame(true);
		}
	}

	void ReplicatePlayerHighlight(float DeltaTime)
	{
		auto HighlightSettings = UPlayerHighlightSettings::GetSettings(CopyPlayer);
		if (HighlightSettings.bPlayerHighlightVisible)
		{
			if (Highlight == nullptr)
			{
				Highlight = SpawnActor(CopyHighlightSettings.HighlightClass);
				Highlight.Player = CopyPlayer;
				Highlight.Settings = CopyHighlightSettings;
				Highlight.Initialize();

				Highlight.AttachToComponent(Mesh, CopyHighlightSettings.HighlightAttachSocket);
			}

			if (CopyHighlightSettings.SpotlightIntensity > 0)
			{
				FQuat SpotlightRotation = CopyPlayer.ViewRotation.Quaternion() * CopyHighlightSettings.SpotlightAngle.Quaternion();
				Highlight.SpotLightComp.SetWorldLocationAndRotation(
					Highlight.ActorLocation
						- SpotlightRotation.ForwardVector * CopyHighlightSettings.SpotlightDistance
						+ ActorTransform.TransformVector(CopyHighlightSettings.SpotlightAttachOffset),
					SpotlightRotation);
			}
		}
		else
		{
			if (Highlight != nullptr)
			{
				Highlight.bFadingOut = true;
				Highlight = nullptr;

				if ((CopyHighlightSettings.SpotlightIntensity != 0 && !CopyHighlightSettings.bSpotlightAffectsWorld) || (CopyHighlightSettings.PointlightIntensity != 0 && !CopyHighlightSettings.bPointlightAffectsWorld))
				{
					Mesh.SetLightingChannels(true, false, false);
				}
			}
		}
	}
};

struct FSplitTraversalPlayerCopyEffectParams
{
	UPROPERTY()
	UDeathRespawnEffectSettings EffectSettings;

	UPROPERTY()
	FPlayerDeathDamageParams DeathParams;

	UPROPERTY()
	ASplitTraversalPlayerCopy Player;

	FSplitTraversalPlayerCopyEffectParams (UDeathRespawnEffectSettings CurrentSettings, FPlayerDeathDamageParams CurrentDeatharams, ASplitTraversalPlayerCopy CurrentPlayer)
	{
		EffectSettings = CurrentSettings;
		DeathParams = CurrentDeatharams;
		Player = CurrentPlayer;
	}
}

class USplitTraversalPlayerCopyEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintPure)
	UHazeSkeletalMeshComponentBase GetSkeletalMesh() const
	{
		return Cast<ASplitTraversalPlayerCopy>(Owner).Mesh;
	}

	UFUNCTION(BlueprintEvent)
	void PlayerDied(FSplitTraversalPlayerCopyEffectParams EffectParams) {}

	UFUNCTION(BlueprintPure)
	FVector GetDeathForceLocation(FVector Direction, ASplitTraversalPlayerCopy SplitCopyPlayer, float CurrentUnitOffset = 50.0)
	{
		auto Settings = UDeathRespawnEffectSettings::GetSettings(SplitCopyPlayer);
		FVector PlayerCenterLocation = SplitCopyPlayer.ActorLocation + FVector(0, 0, 80.0);
		PlayerCenterLocation += Settings.PlayerCenterLocationOffset;

		// Debug::DrawDebugSphere(PlayerCenterLocation, Radius = 20.0, Duration = 10.0);

		if (Direction.Size() == 0.0)
		{
#if EDITOR
			if (Settings.bDebugDrawCenterPositionOnDeath)
			{
				PrintToScreen(f"{this} is debug drawing death location for {SplitCopyPlayer}", 10, FLinearColor::Green);
				Debug::DrawDebugSphere(PlayerCenterLocation, 25.0, 12, FLinearColor::Green, 5.0, 10.0);
			}
#endif
			return PlayerCenterLocation;
		}
		else
		{
#if EDITOR
			if (Settings.bDebugDrawCenterPositionOnDeath)
			{
				PrintToScreen(f"{this} is debug drawing death location for {SplitCopyPlayer}", 10, FLinearColor::Green);
				Debug::DrawDebugSphere(PlayerCenterLocation - (Direction * CurrentUnitOffset), 25.0, 12, FLinearColor::Green, 5.0, 10.0);
			}
#endif
			return PlayerCenterLocation - (Direction * CurrentUnitOffset);
		}
	}
}

class USplitTraversalCopyPartsCapability : UHazeCapability
{
	ASplitTraversalPlayerCopy PlayerCopy;

	default TickGroup = EHazeTickGroup::PostWork;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerCopy = Cast<ASplitTraversalPlayerCopy>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PlayerCopy.ReplicateSwingRope();
	}
}

class USplitTraversalCopySwimmingEffectsHandler : UPlayerSwimmingEffectHandler
{
	UFUNCTION(BlueprintPure)
	FVector GetCopiedLocation(FVector Location) const
	{
		return Location - FVector(500000.0, 0.0, 0.0);
	}

	UFUNCTION(BlueprintPure)
	ASplitTraversalPlayerCopy GetCopyActor() const
	{
		return ASplitTraversalManager::GetSplitTraversalManager().PlayerCopies[Player];
	}

	UFUNCTION(BlueprintPure)
	UHazeSkeletalMeshComponentBase GetCopyMesh() const
	{
		return GetCopyActor().Mesh;
	}

	UFUNCTION(BlueprintPure)
	FVector GetCopyActorLocation() const
	{
		return GetCopyActor().ActorLocation;
	}
}