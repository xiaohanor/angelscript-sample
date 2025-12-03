class AMedallionPlayerStranglingTetherDonut : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY()
	UMaterialParameterCollection GlobalParametersVFX;

	UPROPERTY()
	FRuntimeFloatCurve TetherGlowCurve;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent HelixMesh;
	default HelixMesh.bVisible = false;
	private const float FakeRadius = 950;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;

	USceneComponent MioUIAttachComp;
	USceneComponent ZoeUIAttachComp;

	private FVector OGScale;
	private UMedallionPlayerGloryKillComponent MioKillComp;
	private UMedallionPlayerGloryKillComponent ZoeKillComp;

	private ASanctuaryBossMedallionHydra Hydra = nullptr;
	// laps and loops should ideally be same for players, but animation might not be symmetrical
	TPerPlayer<int> PlayerLaps; 
	TPerPlayer<float> PlayerLoopDegrees;

	const float TetherAttachBackwardsDegreeOffset = 70.0;
	const float HelixSpiralHeightBetweenCoils = 110.0; // based on mesh coils
	const float MaxCoilDegreesPerPlayer = 360.0 * 3.0; // three laps each
	float Blood = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorHiddenInGame(true);
		OGScale = ActorTransform.Scale3D;
		MioKillComp = UMedallionPlayerGloryKillComponent::GetOrCreate(Game::Mio);
		ZoeKillComp = UMedallionPlayerGloryKillComponent::GetOrCreate(Game::Zoe);
		MioUIAttachComp = USceneComponent::Create(this, n"MioUIAttachComp");
		ZoeUIAttachComp = USceneComponent::Create(this, n"ZoeUIAttachComp");
	}

	void MedallionAppearAttach(ASanctuaryBossMedallionHydra StrangledHydra)
	{
		Blood = 0.0;
		Hydra = StrangledHydra;
		PlayerLaps[Game::Mio] = 0;
		PlayerLaps[Game::Zoe] = 0;
		PlayerLoopDegrees[Game::Mio] = 0.0;
		PlayerLoopDegrees[Game::Zoe] = 0.0;
		SetActorHiddenInGame(false);
		HelixMesh.SetVisibility(true);
	}

	void MedallionHide()
	{
		SetActorHiddenInGame(true);
		Hydra = nullptr;

		float TetherEmissiveness = TetherGlowCurve.GetFloatValue(0.0);	
		Material::SetScalarParameterValue(GlobalParametersVFX, n"TetherStrength", TetherEmissiveness);
	}

	float GetTotalDegreesForPlayer(AHazePlayerCharacter Player) const
	{
		return Math::Clamp(PlayerLaps[Player] * 360.0 + PlayerLoopDegrees[Player], 0.0, MaxCoilDegreesPerPlayer);
	}

	float GetTotalDegreesForPlayerWithOffset(AHazePlayerCharacter Player) const
	{
		return Math::Clamp(PlayerLaps[Player] * 360.0 + PlayerLoopDegrees[Player] - TetherAttachBackwardsDegreeOffset, 0.0, MaxCoilDegreesPerPlayer);
	}

	float GetRadius()
	{
		float Scale = GetActorScale3D().X;
		return FakeRadius * Scale;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Hydra != nullptr && !IsHidden())
		{
			FTransform CutoffBoneTransform = Hydra.GetCutBoneTransform();;
			float TotalKillAlpha = MioKillComp.SyncedStrangle.Value + ZoeKillComp.SyncedStrangle.Value;
			TotalKillAlpha *= 0.5;
			float CutMultiplier = Math::Lerp(1.0, 0.635, TotalKillAlpha);

			float TetherEmissiveness = TetherGlowCurve.GetFloatValue(TotalKillAlpha);
			
			Material::SetScalarParameterValue(GlobalParametersVFX, n"TetherStrength", TetherEmissiveness);

			FVector NewScale = OGScale;
			NewScale.X *= CutMultiplier;
			NewScale.Y *= CutMultiplier;
			CutoffBoneTransform.Scale3D = NewScale;
			SetActorTransform(CutoffBoneTransform);
			Blood = Math::Max(Blood, TotalKillAlpha); // blood should never decrase
			Hydra.SkeletalMesh.SetVectorParameterValueOnMaterials(n"Strangling_Location", CutoffBoneTransform.Location);
			Hydra.SkeletalMesh.SetScalarParameterValueOnMaterials(n"Strangling_Strength", SanctuaryMedallionStrangleDeformationCurve.GetFloatValue(TotalKillAlpha));
			Hydra.SkeletalMesh.SetScalarParameterValueOnMaterials(n"Strangling_Blood", 0.0);
			Hydra.SkeletalMesh.SetScalarParameterValueOnMaterials(n"Strangling_Radius", 1500);
			
			const float ExtraToOverlapTetherDegrees = 5;
			{
				float MioPlayerCoilDegrees = GetTotalDegreesForPlayerWithOffset(Game::Mio) + ExtraToOverlapTetherDegrees;
				float HelixVisibleAlpha = 1.0 - Math::Saturate(MioPlayerCoilDegrees / MaxCoilDegreesPerPlayer);
				if (SanctuaryMedallionHydraDevToggles::Draw::HelixDonut.IsEnabled())
					Debug::DrawDebugString(ActorCenterLocation, "Mio Alpha:" + HelixVisibleAlpha, Scale = 2.0);
				HelixMesh.SetScalarParameterValueOnMaterials(n"MioTetherProgress", HelixVisibleAlpha);
			}
			{
				float ZoePlayerCoilDegrees = GetTotalDegreesForPlayerWithOffset(Game::Zoe) + ExtraToOverlapTetherDegrees;
				float HelixVisibleAlpha = 1.0 - Math::Saturate(ZoePlayerCoilDegrees / MaxCoilDegreesPerPlayer);
				if (SanctuaryMedallionHydraDevToggles::Draw::HelixDonut.IsEnabled())
					Debug::DrawDebugString(ActorCenterLocation, "\n\nZoe Alpha:" + HelixVisibleAlpha, Scale = 2.0);
				HelixMesh.SetScalarParameterValueOnMaterials(n"ZoeTetherProgress", HelixVisibleAlpha);
			}
		}
	}

	// previous versions
	FVector GetClosestPointOnDonut(FVector WorldLocation)
	{
		FVector ClosestOnPlane = Math::LinePlaneIntersection(WorldLocation + FVector::UpVector * 10000, WorldLocation - FVector::UpVector * 10000, ActorCenterLocation, ActorUpVector);
		FVector Direction = ClosestOnPlane - ActorCenterLocation;
		

		if (SanctuaryMedallionHydraDevToggles::Draw::Tether.IsEnabled())
		{
			Debug::DrawDebugSphere(ClosestOnPlane, 10);
			Debug::DrawDebugCircle(ActorCenterLocation, FakeRadius, bDrawInForeground = true);
		}

		return ActorCenterLocation + Direction.GetSafeNormal() * FakeRadius;
	}

	FVector GetRightVectorPointOnDonut(FVector WorldLocation, bool bClockwise)
	{
		FVector ClosestOnPlane = Math::LinePlaneIntersection(WorldLocation + FVector::UpVector * 10000, WorldLocation - FVector::UpVector * 10000, ActorCenterLocation, ActorUpVector);
		FVector Direction = ClosestOnPlane - ActorCenterLocation;

		FRotator RotatationTowardsPlayer = FRotator::MakeFromXZ(Direction, ActorUpVector);
		FVector RightVectorDirection;
		
		RightVectorDirection = bClockwise ? -RotatationTowardsPlayer.RightVector : RotatationTowardsPlayer.RightVector;

		return ActorCenterLocation + RightVectorDirection * FakeRadius;
	}
};