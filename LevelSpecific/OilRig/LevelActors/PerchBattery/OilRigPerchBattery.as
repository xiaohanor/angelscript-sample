event void FOilRigPerchBatteryConnectedEvent(TArray<AHazePlayerCharacter> Players);
event void FOilRigPerchBatterDisconnectedEvent();

class AOilRigPerchBattery : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UFauxPhysicsTranslateComponent PerchRoot;

	UPROPERTY(DefaultComponent, Attach = PerchRoot)
	UPerchPointComponent PerchComp;

	UPROPERTY(DefaultComponent, Attach = PerchComp)
	UPerchEnterByZoneComponent PerchLandingComp;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent PlayerWeightComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 6000.0;

	UPROPERTY(EditInstanceOnly)
	AStaticMeshActor BatteryLightActor;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> ConnectedCamShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ConnectedFF;

	UPROPERTY()
	FOilRigPerchBatteryConnectedEvent OnBatteryConnected;

	UPROPERTY()
	FOilRigPerchBatterDisconnectedEvent OnBatteryDisconnected;

	bool bConnected = false;

	bool bStayConnected = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bStayConnected)
		{
			PerchRoot.ApplyImpulse(PerchRoot.WorldLocation, FVector::UpVector * -100.0);
		}

		else if (HasControl())
		{
			if (PerchRoot.RelativeLocation.Z <= PerchRoot.MinZ && !bConnected)
			{
				bool bMioOnPole = PerchComp.IsPlayerOnPerchPoint[0];
				bool bZoeOnPole = PerchComp.IsPlayerOnPerchPoint[1];

				TArray<AHazePlayerCharacter> PerchingPlayers;
				if (bMioOnPole)
					PerchingPlayers.Add(Game::Mio);
				if (bZoeOnPole)
					PerchingPlayers.Add(Game::Zoe);

				CrumbBatteryConnected(PerchingPlayers);
			}
			else if (PerchRoot.RelativeLocation.Z > PerchRoot.MinZ && bConnected)
			{
				CrumbBatteryDisconnected();
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbBatteryConnected(TArray<AHazePlayerCharacter> PerchingPlayers)
	{
		bConnected = true;
		OnBatteryConnected.Broadcast(PerchingPlayers);

		for (AHazePlayerCharacter Player : PerchingPlayers)
		{
			Player.PlayCameraShake(ConnectedCamShake, this, 0.6);
			Player.PlayForceFeedback(ConnectedFF, false, true, this);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbBatteryDisconnected()
	{
		bConnected = false;
		OnBatteryDisconnected.Broadcast();
	}

	UFUNCTION()
	void StayConnected()
	{
		bStayConnected = true;
	}
}