class USanctuaryLightBirdShieldDarknessCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"LightBirdShield");

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 101;

	USanctuaryLightBirdShieldUserComponent UserComp;

	bool bIsInsideShield = false;
	ASanctuaryLightBirdShield InsideLightBirdShield;

	TArray<FName> BlockedTags;

	USpotLightComponent FaceLight;
	float FaceLightInitialintensity = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = USanctuaryLightBirdShieldUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!UserComp.bIsActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!UserComp.bIsActive)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FaceLight = USpotLightComponent::Create(Player);
		FaceLight.LightColor = UserComp.Settings.FaceLightColor;
		FaceLight.SetIntensity(0.0);
		FaceLight.SetCastShadows(false);
		FaceLight.AttachToComponent(Player.Mesh, n"Head", EAttachmentRule::SnapToTarget);
		FaceLight.RelativeLocation = FVector::ForwardVector * 50.0;
		FVector ToFace = Player.Mesh.GetSocketLocation(n"Head") - FaceLight.WorldLocation;
		FaceLight.WorldRotation = ToFace.Rotation();

		FaceLightInitialintensity = FaceLight.Intensity;

		for (auto Settings : UserComp.Settings.Settings)
			Player.ApplySettings(Settings, this);

		if (Player.IsMio())
		{
			for (auto Settings : UserComp.Settings.MioSettings)
				Player.ApplySettings(Settings, this);
		}

		if (Player.IsZoe())
		{
			for (auto Settings : UserComp.Settings.ZoeSettings)
				Player.ApplySettings(Settings, this);
		}

		for (auto Tag : UserComp.Settings.BlockTags)
			Player.BlockCapabilities(Tag, this);

		BlockedTags = UserComp.Settings.BlockTags;

		UserComp.DarknessAmount = 0.0;

		UserComp.DarknessComp = Niagara::SpawnLoopingNiagaraSystemAttached(UserComp.Settings.DarknessVFX, Player.Mesh);
//		UserComp.DarknessComp = Niagara::SpawnOneShotNiagaraSystemAttached(UserComp.Settings.DarknessVFX, Player.Mesh);
		UserComp.DarknessComp.SetTranslucentSortPriority(3000);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearSettingsByInstigator(this);
		Player.ClearCameraSettingsByInstigator(this);

		for (auto Tag : BlockedTags)
			Player.UnblockCapabilities(Tag, this);

		UserComp.DarknessComp.DestroyComponent(Owner);
	
		FaceLight.DestroyComponent(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		bool bIsInsideDarkness = true;

		

//		if (UserComp.InsideDarknessVolumes > 0)
//			bIsInsideDarkness = true;

//		if (UserComp.DarknessVolumes.Num() > 0)
//			bIsInsideDarkness = true;

		TListedActors<ASanctuaryLightBirdShield> LightBirdShields;
		auto LightBirdShieldsCopy = LightBirdShields.CopyAndInvalidate();
		for (auto LightBirdShield : LightBirdShieldsCopy)
		{
//			if (LightBirdShield.bIsIlluminating && Player.ActorCenterLocation.Distance(LightBirdShield.ActorLocation) < LightBirdShield.CurrentRadius)
			if (Player.ActorCenterLocation.Distance(LightBirdShield.ActorLocation) < LightBirdShield.CurrentRadius)
			{
				bIsInsideDarkness = false;

				if (!bIsInsideShield)
				{
					bIsInsideShield = true;
					auto EventManager = TListedActors<ASanctuaryLightBirdShieldEventManager>().Single;
					if (EventManager != nullptr && EventManager.bBroadcastEvents)
						EventManager.OnPlayerEnterShield.Broadcast(Player);

					InsideLightBirdShield = LightBirdShield;
					USanctuaryLightBirdShieldEventHandler::Trigger_ZoeEnterShield(InsideLightBirdShield);
				}
			}
		}

		if (bIsInsideDarkness && bIsInsideShield)
		{
			bIsInsideShield = false;

			auto EventManager = TListedActors<ASanctuaryLightBirdShieldEventManager>().Single;
			if (EventManager != nullptr && EventManager.bBroadcastEvents)
				EventManager.OnPlayerLeaveShield.Broadcast(Player);	

			if (InsideLightBirdShield != nullptr)
			{
				USanctuaryLightBirdShieldEventHandler::Trigger_ZoeExitShield(InsideLightBirdShield);		
				InsideLightBirdShield = nullptr;
			}
		}

		if (bIsInsideDarkness)
			UserComp.DarknessAmount = Math::Clamp(UserComp.DarknessAmount + UserComp.DarknessRate.Get() * DeltaTime, 0.0, 1.0);
		else
			UserComp.DarknessAmount = Math::Clamp(UserComp.DarknessAmount - UserComp.DarknessRate.Get() * 10.0 * DeltaTime, 0.0, 1.0);

//		UserComp.DarknessAmount = Math::Clamp(UserComp.DarknessAmount + (bIsInsideDarkness ? 1.0 : -1.0) * UserComp.DarknessRate * DeltaTime, 0.0, 1.0);

		PrintToScreen("" + Player.Name + " darkness amount: " + UserComp.DarknessAmount, 0.0, FLinearColor::Green);
		PrintToScreen("" + Player.Name + " darkness voluemes: " + UserComp.InsideDarknessVolumes, 0.0, FLinearColor::Green);
		PrintToScreen("" + Player.Name + " darkness rate: " + UserComp.DarknessRate.Get(), 0.0, FLinearColor::Green);

//		Debug::DrawDebugSphere(Player.ActorLocation, (1.0 - DarknessAmount) * 300.0, 12, FLinearColor::Red, 5.0, 0.0);

		UserComp.DarknessComp.SetNiagaraVariableFloat("SpawnRate", (UserComp.DarknessAmount > SMALL_NUMBER ? 20.0 : 0.0));

		FVector HeadLocation = Player.Mesh.GetSocketLocation(n"Head");
		if (Player.IsZoe())
			Material::SetVectorParameterValue(UserComp.Settings.GlobalParametersVFX, n"SphereMaskDarknessFace", FLinearColor(HeadLocation.X, HeadLocation.Y, HeadLocation.Z, 1.0));
//		Debug::DrawDebugPoint(HeadLocation, 20.0, FLinearColor::Green, 0.0);
	
		FaceLight.SetIntensity(UserComp.Settings.FaceLightIntensity * UserComp.DarknessAmount);

//		Debug::DrawDebugPoint(FaceLight.WorldLocation, 20.0, FLinearColor::Green, 0.0);
	
	}
};