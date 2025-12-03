event void FMaxSecurityLaserHellDoor();

class AMaxSecurityLaserHellDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent DoorMeshRoot01;

	UPROPERTY(DefaultComponent, Attach = DoorMeshRoot01)
	UStaticMeshComponent DoorMesh01;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent DoorMeshRoot02;

	UPROPERTY(DefaultComponent, Attach = DoorMeshRoot02)
	UStaticMeshComponent DoorMesh02;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DoorProximityCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent AdditionalDoorProximityCollision;

	UPROPERTY(EditInstanceOnly)
	bool bShouldUseAdditionalDoorProximityCollision = false;

	UPROPERTY()
	FHazeTimeLike OpenDoorTimelike;
	default OpenDoorTimelike.Duration = 0.15;

	UPROPERTY(EditAnywhere)
	UHazeCameraSpringArmSettingsDataAsset DoorProximityCamSettings;

	UPROPERTY(EditInstanceOnly)
	TArray<AHazePointLight> ProximityPointLights;

	UPROPERTY(EditInstanceOnly)
	AMaxSecurityLaserHellLaserAlarm LeftAlarm;
	UPROPERTY(EditInstanceOnly)
	AMaxSecurityLaserHellLaserAlarm RightAlarm;

	UPROPERTY()
	FLinearColor RedLightColor;
	UPROPERTY()
	FLinearColor GreenLightColor;
	UPROPERTY()
	FLinearColor AlarmMeshRedColor;
	UPROPERTY()
	FLinearColor AlarmMeshGreenColor;

	UPROPERTY(EditInstanceOnly)
	float KillTimerDuration = 5;
	
	UPROPERTY()
	FMaxSecurityLaserHellDoor OnDoorOpened;
	
	float KillTimer = 0;
	bool bShouldTickKillTimer = false;
	bool bAlarmLightActive = false;
	TArray<AHazePlayerCharacter> KillList;

	bool bDoorIsOpen = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OpenDoorTimelike.BindUpdate(this, n"OpenDoorTimelikeUpdate");
		DoorProximityCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnDoorProximityOverlap");
		DoorProximityCollision.OnComponentEndOverlap.AddUFunction(this, n"OnDoorProximityEndOverlap");

		if(bShouldUseAdditionalDoorProximityCollision)
			AdditionalDoorProximityCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnDoorProximityOverlap");
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(bShouldUseAdditionalDoorProximityCollision)
		{
			AdditionalDoorProximityCollision.SetVisibility(true);
		}
		else
		{
			AdditionalDoorProximityCollision.SetVisibility(false);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bAlarmLightActive)
		{
			BlinkAlarmLights(DeltaSeconds);
		}

		if(!HasControl())
			return;

		if(bShouldTickKillTimer)
		{
			if(KillList.IsEmpty())
			{
				bShouldTickKillTimer = false;
				KillTimer = 0;
				CrumbSetAlarmLightsActive(false);
			}

			for(int i = KillList.Num() - 1; i >= 0; i--)
			{
				if(KillList[i].IsPlayerDead())
					KillList.RemoveAt(i);
			}

			KillTimer += DeltaSeconds;
			if(KillTimer >= KillTimerDuration)
			{
				if(KillList.Num() == 1)
				{
					LeftAlarm.CrumbShootLaser(KillList[0]);
					RightAlarm.CrumbShootLaser(KillList[0]);
				}
				else
				{
					AHazePlayerCharacter LeftAlarmTarget;
					LeftAlarmTarget = LeftAlarm.CrumbShootLaser(nullptr);
					RightAlarm.CrumbShootLaser(LeftAlarmTarget.OtherPlayer);
				}

				for(auto Player : KillList)
					NetKillPlayer(Player, KillList.Num());

				bShouldTickKillTimer = false;
				KillTimer = 0;
				KillList.Empty();
				CrumbSetAlarmLightsActive(false);
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetKillPlayer(AHazePlayerCharacter Player, int ListLength)
	{
		if(!Player.HasControl())
			return;

		Player.KillPlayer();
	}

	void OpenDoor()
	{
		OpenDoorTimelike.PlayFromStart();
		bDoorIsOpen = true;
		bShouldTickKillTimer = false;
		KillList.Empty();
		SetAlarmLightsActive(false, true);
		KillTimer = 0;
		OnDoorOpened.Broadcast();

		FLaserHellDoorEventData Data;
		Data.DoorActor = this;
		UMaxSecurityLaserHellEventHandler::Trigger_DoorOpened(this, Data);
	}

	void CloseDoor()
	{
		if(!HasControl())
			return;

		CrumbCloseDoor();	
	}

	UFUNCTION(CrumbFunction)
	void CrumbCloseDoor()
	{
		if(bDoorIsOpen)
		{
			OpenDoorTimelike.ReverseFromEnd();
			bDoorIsOpen = false;

			FLaserHellDoorEventData Data;
			Data.DoorActor = this;
			UMaxSecurityLaserHellEventHandler::Trigger_DoorClosed(this, Data);
			SetAlarmLightsActive(false);
		}		

		if(!HasControl())
			return;

		for(auto Player : Game::Players)
		{
			if(DoorProximityCollision.IsOverlappingActor(Player))
			{
				StartKillTimer(Player);
			}
		}
	}

	UFUNCTION()
	private void OpenDoorTimelikeUpdate(float CurrentValue)
	{
		float NewLoc = Math::Lerp(0, 190, CurrentValue);
		DoorMeshRoot01.SetRelativeLocation(FVector(0, NewLoc, 0));
		DoorMeshRoot02.SetRelativeLocation(FVector(0, -NewLoc, 0));
	}

	UFUNCTION()
	private void OnDoorProximityOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                    UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                    bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		Player.ApplyCameraSettings(DoorProximityCamSettings, 2, this);
		
		if(!HasControl())
			return;
		
		if(bDoorIsOpen)
			return;

		StartKillTimer(Player);
	}

	UFUNCTION()
	private void OnDoorProximityEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                       UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		Player.ClearCameraSettingsByInstigator(this);
	}

	void StartKillTimer(AHazePlayerCharacter Player)
	{
		if(KillList.Contains(Player))
			return;
		
		KillList.AddUnique(Player);
		CrumbSetAlarmLightsActive(true);
		bShouldTickKillTimer = true;
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetAlarmLightsActive(bool bActive, bool bDoorWasOpened = false)
	{
		if(bActive)
		{
			bAlarmLightActive = true;
			SetLightColor(RedLightColor);

			FLaserHellDoorEventData Data;
			Data.DoorActor = this;
			UMaxSecurityLaserHellEventHandler::Trigger_DoorAlarmStart(this, Data);
		}
		else
		{
			bAlarmLightActive = false;
			
			LeftAlarm.SetMeshColor(FLinearColor::White);
			RightAlarm.SetMeshColor(FLinearColor::White);
			SetLightIntensity(0.0);
			SetLightColor(RedLightColor);

			FLaserHellDoorEventData Data;
			Data.DoorActor = this;
			UMaxSecurityLaserHellEventHandler::Trigger_DoorAlarmStop(this, Data);
		}

		if(bDoorWasOpened)
		{
			SetLightColor(GreenLightColor);
			SetLightIntensity(1500.0);

			LeftAlarm.SetMeshColor(AlarmMeshGreenColor);
			RightAlarm.SetMeshColor(AlarmMeshGreenColor);
		}
	}

	void SetAlarmLightsActive(bool bActive, bool bDoorWasOpened = false)
	{
		if(bActive)
		{
			bAlarmLightActive = true;
			SetLightColor(RedLightColor);

			FLaserHellDoorEventData Data;
			Data.DoorActor = this;
			UMaxSecurityLaserHellEventHandler::Trigger_DoorAlarmStart(this, Data);
		}
		else
		{
			bAlarmLightActive = false;
			
			LeftAlarm.SetMeshColor(FLinearColor::White);
			RightAlarm.SetMeshColor(FLinearColor::White);
			SetLightIntensity(0.0);
			SetLightColor(RedLightColor);

			FLaserHellDoorEventData Data;
			Data.DoorActor = this;
			UMaxSecurityLaserHellEventHandler::Trigger_DoorAlarmStop(this, Data);
		}

		if(bDoorWasOpened)
		{
			SetLightColor(GreenLightColor);
			SetLightIntensity(1500.0);

			LeftAlarm.SetMeshColor(AlarmMeshGreenColor);
			RightAlarm.SetMeshColor(AlarmMeshGreenColor);
		}
	}

	private void BlinkAlarmLights(float DeltaTime)
	{
		float Alpha = Math::Abs(Math::Sin(Time::GameTimeSeconds * 7.0));

		SetLightIntensity(Math::Lerp(0, 4000, Alpha));
		
		FLinearColor NewColor = Math::Lerp(FLinearColor::White, AlarmMeshRedColor, Alpha);
		LeftAlarm.SetMeshColor(NewColor);
		RightAlarm.SetMeshColor(NewColor);
	}

	void SetLightColor(FLinearColor NewColor)
	{
		for(auto Light : ProximityPointLights)
		{
			Light.LightComponent.SetLightColor(NewColor);
		}
	}

	void SetLightIntensity(float NewIntensity)
	{
		for(auto Light : ProximityPointLights)
		{
			Light.LightComponent.SetIntensity(NewIntensity);
		}
	}

	UFUNCTION(CallInEditor)
	void SetProximityLightIntensityEditor(float Intensity)
	{
		for(auto Light : ProximityPointLights)
			Light.LightComponent.SetIntensity(Intensity);
	}

	UFUNCTION(CallInEditor)
	void SetAlarmMeshTint(FLinearColor Color)
	{
		LeftAlarm.SetMeshColor(Color);
		RightAlarm.SetMeshColor(Color);
	}
};