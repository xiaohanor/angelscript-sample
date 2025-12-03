class UMoonMarketThundercloudPotionCapability : UMoonMarketPlayerShapeshiftCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::ActionMovement;

	AMoonMarketThunderCloud Cloud;
	UMoonMarketThundercloudPotionComponent CloudComp;
	USkeletalMesh SkeletalMeshAsset;

	//MOVEMENT
	UPlayerMovementComponent MoveComp;
	USweepingMovementData Movement;
	FHazeAcceleratedFloat CurrentHeight;

	//SHADOW DECAL

	UMaterialInstanceDynamic DynamicMaterial;

	UDecalComponent ShadowDecal;

	const float DecalSize = 0.4;
	const float DecalOpacity = 0.7;

	float LastThunderActivationTime;
	TOptional<FVector> LastGroundHeight;
	const float StepHeight = 20;

	FHazeAcceleratedVector CurrentAcceleration;

	int Uses;
	int MaxTutorialUses = 2;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UMoonMarketPlayerShapeshiftCapability::Setup();
		CloudComp = UMoonMarketThundercloudPotionComponent::Get(Owner);

		SkeletalMeshAsset = Player.Mesh.SkeletalMeshAsset;
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();

		//ShadowDecal = UDecalComponent::Create(Player, n"ThurderCloudShadow");
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UMoonMarketPlayerShapeshiftCapability::OnActivated();

		Player.BlockCapabilitiesExcluding(CapabilityTags::Movement, CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.BlockCapabilities(n"PlayerShadow", this);

		LastThunderActivationTime = 0;
		Player.ApplyCameraSettings(CloudComp.CameraSettings, 2.0, this);

		Player.Mesh.AddComponentVisualsBlocker(this);

		Cloud = Cast<AMoonMarketThunderCloud>(ShapeshiftInto(CloudComp.CloudClass));
		MoveComp.SetupShapeComponent(Cloud.Capsule);


		ShadowDecal = Cloud.ShadowDecal;
		DynamicMaterial = Material::CreateDynamicMaterialInstance(ShadowDecal, ShadowDecal.DecalMaterial);
		ShadowDecal.SetDecalMaterial(DynamicMaterial);

		const float StartingHeight = Owner.ActorLocation.Z + 200;
		CurrentHeight.SnapTo(StartingHeight, 1);
		Owner.SetActorLocation(FVector(Owner.ActorLocation.X, Owner.ActorLocation.Y, StartingHeight));

		if (Uses < MaxTutorialUses)
		{
			FTutorialPrompt Prompt;
			Prompt.Action = ActionNames::PrimaryLevelAbility;
			Prompt.Text = NSLOCTEXT("MoonMarketThundercloud", "ThunderPrompt", "Lightning Strike");
			Player.ShowTutorialPrompt(Prompt, this);
		}
		
		MoveComp.ApplySplineCollision(TListedActors<AMoonMarketThunderCloudSplineCollisionManager>().Single.CollisionSplines, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveComp.ClearSplineCollision(this);
		UMoonMarketPlayerShapeshiftCapability::OnDeactivated();
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.UnblockCapabilities(n"PlayerShadow", this);
		Player.ResetMovement();
		MoveComp.SetupShapeComponent(Player.CapsuleComponent);
		Cloud.Capsule.AddComponentCollisionBlocker(this);

		RemoveVisualBlocker();
		Player.ClearSettingsByInstigator(this);
		Player.ClearCameraSettingsByInstigator(this);
		ShadowDecal.SetHiddenInGame(true);

		Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float Percentage = Math::Clamp(Time::GetGameTimeSince(LastThunderActivationTime) / CloudComp.ThunderCooldown, 0, 1);
		const float LightningSpawnRate = CloudComp.StaticChargeCurve.GetFloatValue(Percentage) * CloudComp.StaticLightningAmount;
		Cloud.Cloud.SetFloatParameter(n"LightningSpawnRate", LightningSpawnRate);

		FHitResultArray Hits = TraceForGround();
		if(Hits.bHasBlockingHit)
		{
			Cloud.Rain.SetFloatParameter(n"SplashSpawnRate", 20);
			Cloud.Rain.SetVectorParameter(n"SplashPositionXYZ", Cloud.ActorTransform.InverseTransformPositionNoScale(Hits.FirstBlockHit.ImpactPoint - Cloud.Rain.RelativeLocation));
		}
		else
		{
			Cloud.Rain.SetFloatParameter(n"SplashSpawnRate", 0);
		}
		
		HandleShadowDecal(Hits);
		
		FHitResult NPCHit = TraceForNPC();
		if(NPCHit.bBlockingHit)
		{
			auto ThunderResponseComp = UMoonMarketThunderStruckComponent::Get(NPCHit.Actor);
			if(ThunderResponseComp != nullptr)
			{
				if(!ThunderResponseComp.WasRainedOnRecently())
					ThunderResponseComp.OnRainedOn.Broadcast(FMoonMarketInteractingPlayerEventParams(Player));

				ThunderResponseComp.LastRainFrame = Time::FrameNumber;
				ThunderResponseComp.LastRainTime = Time::GameTimeSeconds;
			}
		}

		if(HasControl())
		{
			if(WasActionStarted(ActionNames::PrimaryLevelAbility))
			{
				FVector ImpactPoint = Cloud.ActorLocation - FVector::UpVector * CloudComp.HoverHeight;
				if(Hits.HasBlockHits())
					ImpactPoint = Hits.FirstBlockHit.ImpactPoint;

				if(Time::GameTimeSeconds - LastThunderActivationTime > CloudComp.ThunderCooldown)
					CrumbLightningStrike(ImpactPoint);
			}
		}

		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				FVector MovementInput = MoveComp.MovementInput;
				const float LerpDuration = MovementInput.Size() > 0 ? 0.3 : 0.5;
				CurrentAcceleration.AccelerateTo(MovementInput.GetSafeNormal(), LerpDuration, DeltaTime);
				Movement.AddHorizontalVelocity(CurrentAcceleration.Value * 500);

				CurrentHeight.Value = Owner.ActorLocation.Z;
				Movement.SetRotation(Player.ViewRotation.ForwardVector.VectorPlaneProject(FVector::UpVector).Rotation());

				if(Hits.HasBlockHits())
				{
					FHitResult BestBlockingHit = Hits.FirstBlockHit;
					
					for(auto Hit : Hits)
					{
						if(Hit.Component.CollisionObjectType == ECollisionChannel::WorldGeometry)
						{
							BestBlockingHit = Hit;
							break;
						}
					}

					//Debug::DrawDebugPoint(BestBlockingHit.ImpactPoint, 10);

					if(!LastGroundHeight.IsSet() || BestBlockingHit.ImpactPoint.Z - LastGroundHeight.Value.Z < StepHeight || Cast<ALandscape>(BestBlockingHit.Component.Owner) != nullptr)
					{
						const float TargetHeight = BestBlockingHit.ImpactPoint.Z + CloudComp.HoverHeight;

						CurrentHeight.Value = Math::FInterpConstantTo(CurrentHeight.Value, TargetHeight, DeltaTime, 300);

						FVector Delta = FVector::UpVector * (CurrentHeight.Value - Owner.ActorLocation.Z);
						//Debug::DrawDebugSphere(Owner.ActorLocation + Delta);
						Movement.AddDeltaWithCustomVelocity(Delta, FVector::ZeroVector);
						LastGroundHeight.Set(BestBlockingHit.ImpactPoint);
					}
				}
				else
				{
					LastGroundHeight.Reset();
					Movement.AddVerticalVelocity(FVector::DownVector * 500);
				}

			}
			else
			{
				if(MoveComp.HasGroundContact())
					Movement.ApplyCrumbSyncedGroundMovement();
				else
					Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMove(Movement);
		}
	}

	void HandleRotation(FVector MovementInput, float DeltaTime)
	{
		TOptional<FQuat> TargetRotation;

		if(!MoveComp.HorizontalVelocity.IsNearlyZero())
			TargetRotation.Set(MoveComp.HorizontalVelocity.ToOrientationQuat());
		
		if(!TargetRotation.IsSet())
			return;

		Movement.SetRotation(Math::QInterpConstantTo(Player.GetActorQuat(), TargetRotation.Value, DeltaTime, 360));
	}

	UFUNCTION(CrumbFunction)
	void CrumbLightningStrike(FVector ImpactPoint)
	{
		FMoonMarketThunderEventParams Params;
		Params.StrikeLocation = ImpactPoint;
		UMoonMarketThunderCloudEventHandler::Trigger_OnThunderStrike(Cloud, Params);
		LastThunderActivationTime = Time::GameTimeSeconds;

		FVector SpawnLocation = Cloud.ActorTransform.TransformPositionNoScale(FVector(0, 0, -100));
		FQuat SpawnRotation = FQuat(FVector::RightVector, PI);
		FTransform SpawnTransform = FTransform(SpawnRotation, SpawnLocation);

		AMoonMarketLightningStrike Lightning = SpawnActor(CloudComp.LightningClass, bDeferredSpawn = true);
		Lightning.ImpactPoint = ImpactPoint;
		Lightning.OwningPlayer = Player;
		FinishSpawningActor(Lightning, SpawnTransform);
		Lightning.AttachToActor(Cloud, AttachmentRule = EAttachmentRule::KeepWorld);

		Uses++;

		if (Uses >= MaxTutorialUses)
			Player.RemoveTutorialPromptByInstigator(this);
		
		float MaxDistance = 600.0;
		for (AHazePlayerCharacter WorldPlayer : Game::Players)
		{
			WorldPlayer.PlayWorldCameraShake(CloudComp.CameraShake, this, Player.ActorLocation, MaxDistance / 2.0, MaxDistance);
			
			if (WorldPlayer == Player)
			{
				WorldPlayer.PlayForceFeedback(CloudComp.LightningStrikeForceFeedbackTrigger, false, false, this);
			}
			else
			{
				float Dist = WorldPlayer.GetDistanceTo(Player);
				float Intensity = Math::Saturate(MaxDistance / Dist); 
				WorldPlayer.PlayForceFeedback(CloudComp.LightningStrikeForceFeedback, false, false, this, Intensity);
				Print(f"{Intensity=}");
			}
		}
	}

	FHitResultArray TraceForGround()
	{
		FHazeTraceSettings SphereTrace = Trace::InitObjectType(EObjectTypeQuery::WorldStatic);
		SphereTrace.UseSphereShape(10);

		const FVector Start = Owner.ActorLocation;
		const float TraceDistance = CloudComp.HoverHeight + StepHeight;
		const FVector End = Start + FVector::DownVector * TraceDistance;

		// FHazeTraceDebugSettings DebugSettings;
		// DebugSettings.Thickness = 2;
		// DebugSettings.TraceColor = FLinearColor::LucBlue;
		// SphereTrace.DebugDraw(DebugSettings);

		return SphereTrace.QueryTraceMulti(Start, End);
	}

	FHitResult TraceForNPC()
	{
		FHazeTraceSettings SphereTrace = Trace::InitObjectType(EObjectTypeQuery::Pawn);
		SphereTrace.UseSphereShape(30);

		const FVector Start = Owner.ActorLocation;
		const float TraceDistance = CloudComp.HoverHeight + StepHeight;
		const FVector End = Start + FVector::DownVector * TraceDistance;

		// FHazeTraceDebugSettings DebugSettings;
		// DebugSettings.Thickness = 2;
		// DebugSettings.TraceColor = FLinearColor::LucBlue;
		// SphereTrace.DebugDraw(DebugSettings);

		return SphereTrace.QueryTraceSingle(Start, End);
	}

	void HandleShadowDecal(FHitResultArray GroundHits)
	{
		if (GroundHits.HasBlockHits())
		{
			ShadowDecal.SetHiddenInGame(false);
			ShadowDecal.SetWorldLocation(Cloud.ActorLocation + FVector::DownVector * ShadowDecal.DecalSize.X);

			DynamicMaterial.SetScalarParameterValue(n"Decal_Opacity", DecalOpacity);
		}
		else
		{
			ShadowDecal.SetHiddenInGame(true);
		}
	}
};