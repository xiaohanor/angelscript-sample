UCLASS(NotBlueprintable)
class USkylineSmallBossTractorBeamComponent : UNiagaraComponent
{
	UPROPERTY(EditAnywhere)
	FHazeTimeLike TractorBeamOpacityTimelike;
	default TractorBeamOpacityTimelike.UseLinearCurveZeroToOne();
	default TractorBeamOpacityTimelike.Duration = 0.5;
	float TractorBeamOpacity = 0.0;

	ASkylineBallBossSmallBoss SmallBoss = nullptr;
	UMaterialInstanceDynamic ObjectOverlayMaterialDynamic = nullptr;

	private FHazeTimeLike FakeUpdate;
	default FakeUpdate.Duration = 100.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TractorBeamOpacityTimelike.BindUpdate(this, n"TractorBeamOpacityTimelikeUpdate");
		FakeUpdate.BindUpdate(this, n"UpdateTractorBeam");
	}

	void SetupTractorBeamMaterial(UStaticMeshComponent MeshComp)
	{
		if (MeshComp.OverlayMaterial == nullptr)
			return;
		ObjectOverlayMaterialDynamic = Material::CreateDynamicMaterialInstance(Owner, MeshComp.OverlayMaterial);
		MeshComp.SetOverlayMaterial(ObjectOverlayMaterialDynamic);
		ObjectOverlayMaterialDynamic.SetScalarParameterValue(n"SPHEREMASK_Radius", 0.0);
	}

	UFUNCTION()
	private void TractorBeamOpacityTimelikeUpdate(float NewValue)
	{
		TractorBeamOpacity = NewValue;
	}

	void Start()
	{
		TryCacheBallBoss();
		FakeUpdate.PlayFromStart();
		TractorBeamOpacityTimelike.PlayFromStart();
	}

	UFUNCTION()
	void TractorBeamLetGo()
	{
		TractorBeamOpacityTimelike.Reverse();
	}

	void Stop()
	{
		FakeUpdate.Stop();
	}

	// Not ticking, I guess because it's a niagara comp? 
	// Using Fake update via timelike instead 👍
	// UFUNCTION(BlueprintOverride)
	// void Tick(float DeltaSeconds)
	// {
	// 	PrintToScreen("Ticking");
	// }

	UFUNCTION()
	private void UpdateTractorBeam(float NotDeltaTimeDontUseThis)
	{
		TryCacheBallBoss();

		if (Asset == nullptr)
			return;

		if (SmallBoss == nullptr)
			return;

		// if (SkylineBallBoss::bDebugDraw && ObjectOverlayMaterialDynamic == nullptr)
		// 	PrintToScreen("USkylineBallBossTractorBeamComponent : hasn't called SetupTractorBeamMaterial on " + Owner.GetName(), 0.0, ColorDebug::Ruby);

		bool bShouldBeVisible = TractorBeamOpacity > KINDA_SMALL_NUMBER;
		if (bShouldBeVisible != this.IsVisible())
			SetVisibility(bShouldBeVisible);

		if (SkylineBallBossDevToggles::DrawTractorBeam.IsEnabled())
			Debug::DrawDebugSphere(WorldLocation, 100.0, 12, ColorDebug::Eggblue, 3.0, 0.0, true);

		if (TractorBeamOpacity > KINDA_SMALL_NUMBER)
		{
			float EasedFade = Math::EaseIn(0.0, 1.0, TractorBeamOpacity,5.0); // // trivia: did you know humans don't perceive alpha linearly? this looks kind of linear in game.
			SetNiagaraVariableFloat("OPACITY_GlobalFade", EasedFade);
			if (ObjectOverlayMaterialDynamic != nullptr)
				ObjectOverlayMaterialDynamic.SetScalarParameterValue(n"SPHEREMASK_Radius", 220.0 * TractorBeamOpacity);
		}

		if (SmallBoss != nullptr)
		{
			FVector ToBall = SmallBoss.ActorLocation - WorldLocation;
			ToBall = ToBall.GetSafeNormal() * (ToBall.Size() - SmallBoss.Radius * 1.05);
			float MagicOffsetRadius = 150.0;
			FVector OffsetCarPosition = WorldLocation + ToBall.GetSafeNormal() * MagicOffsetRadius;
			SetVectorParameter(n"BeamStart", OffsetCarPosition);
			SetVectorParameter(n"BeamEnd", WorldLocation + ToBall);
			FLinearColor PositionAsColorwtf = FLinearColor(OffsetCarPosition.X, OffsetCarPosition.Y, OffsetCarPosition.Z);
			if (ObjectOverlayMaterialDynamic != nullptr)
				ObjectOverlayMaterialDynamic.SetVectorParameterValue(n"ShieldOriginV3", PositionAsColorwtf);
		}
	}

	private void TryCacheBallBoss()
	{
		if (SmallBoss == nullptr)
		{
			TListedActors<ASkylineBallBossSmallBoss> SmallBosses;
			SmallBoss = SmallBosses.GetSingle();
		}
	}
}