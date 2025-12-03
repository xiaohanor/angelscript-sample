asset WallRunSettings of UPlayerWallRunSettings
{
	GravityStrength = 100;
}

asset WallScrambleSettings of UPlayerWallScrambleSettings
{
	FloorHeightGain = 2500.0;
}

class URotatingCameraDebugCapability : UHazePlayerCapability
{
	float LastDegrees;
	const float DEFAULT_PLAYER_CAMERA_DISTANCE = 438.0;
	ASpotLight Light;
	AGameSky Sky;

	const bool bRotateHalfway = false;
	float SignDir = 1.0;
	float LastYaw = 0.0;

	const bool bUpdateRotation = true;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{	
		return true;	
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(bUpdateRotation)
		{
			UControlRotationSettings::SetOverrideControlRotation(Player, true, this);
			UControlRotationSettings::SetControlRotationOverride(Player, Player.GetViewRotation(), this);
		}

		Player.CastCinematicShadow = false;
		Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen);
		Player.OtherPlayer.BlockCapabilities(n"Visibility", this);

		Player.Mesh.CastShadow = false;

		Light = SpawnActor(ASpotLight, Player.GetActorLocation());
		Light.LightComponent.Mobility = EComponentMobility::Movable;

		UPlayerWallRunComponent WallRunComp = UPlayerWallRunComponent::Get(Player);
		WallRunComp.Settings = WallRunSettings;		

		UPlayerWallScrambleComponent WallScrambleComp = UPlayerWallScrambleComponent::Get(Player);
		//WallScrambleComp.Settings = WallScrambleSettings;

		Sky = AGameSky::Get();
		Sky.SkyLight.Mobility = EComponentMobility::Movable;
		Sky.DirectionalLight.Mobility = EComponentMobility::Movable;
		Sky.Root.Mobility = EComponentMobility::Movable;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		UpdateSpotlight();
		UpdateRotation(DeltaTime);
	}

	private void UpdateSpotlight()
	{
		FVector PlayerLocation = Player.GetActorCenterLocation();

		FVector LightLoc = PlayerLocation;
		LightLoc.X += 300;
		LightLoc.Z -= 25;

		Light.SetActorRotation(FRotator(200, 0, 0));

		Light.LightComponent.MaxDistanceFadeRange = 1000;
		Light.SpotLightComponent.AttenuationRadius = 10000;
		Light.SpotLightComponent.SetInnerConeAngle(90);
		Light.SpotLightComponent.SetIntensity(10000);

		Light.SetActorLocation(LightLoc);

		Sky.SetActorLocation(PlayerLocation);
	}

	private void UpdateRotation(float DeltaTime)
	{
		if(!bUpdateRotation)
			return;

		FRotator CurrRot = Player.ViewRotation;		
		if(!bRotateHalfway)
			CurrRot.Yaw += (10 * DeltaTime);
		else
		{
			CurrRot.Yaw -= (20 * DeltaTime) * SignDir;

			if(CurrRot.Yaw >= 0
			&& LastYaw < 0)
				SignDir *= -1;
		}

		Player.SetCameraDesiredRotation(CurrRot, this);
		LastYaw = CurrRot.Yaw;
	}
}