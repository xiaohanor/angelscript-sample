asset SummitTopDownSwingingAxePlayerHitSheet of UHazeCapabilitySheet
{
	Capabilities.Add(USummitTopDownSwingingAxePlayerHitCapability);
	Components.Add(USummitTopDownSwingingAxePlayerHitComponent);
	Components.Add(URagdollComponent);
}

event void FAxeHitPlayerForVO(AHazePlayerCharacter Player);

class ASummitTopDownSwingingAxe : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000.0;

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TempLogTransformComp;

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	USceneComponent ProngRoot;

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UHazeMovablePlayerTriggerComponent PlayerHitTrigger;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;
	default RequestComp.PlayerSheets.Add(SummitTopDownSwingingAxePlayerHitSheet);

	UPROPERTY(EditAnywhere, Category = "Setup")
	float GroundHeightOffset = -5150.0;

	UPROPERTY(EditAnywhere, Category = "Setup")
	float PlayerKillPlaneHeightOffset = -8200.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float SwingMaxAngle = 40.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float SwingDuration = 2.5;

	UPROPERTY(EditAnywhere, Category = "Ragdoll")
	TPerPlayer<float> RagdollImpulseSizeSideways;
	default RagdollImpulseSizeSideways[EHazePlayer::Zoe] = 140000;//60000.0;
	default RagdollImpulseSizeSideways[EHazePlayer::Mio] = 60000;//20000.0;

	UPROPERTY(EditAnywhere, Category = "Ragdoll")
	TPerPlayer<float> RagdollImpulseSizeUpwards;
	default RagdollImpulseSizeUpwards[EHazePlayer::Zoe] = 140000.0;
	default RagdollImpulseSizeUpwards[EHazePlayer::Mio] = 60000.0;

	UPROPERTY(EditAnywhere, Category = "Ragdoll")
	float MaxRagdollDuration = 1.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bReverseSwing = false;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bVisualizeSwingInEditor = false;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> PassByCamShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect PassByRumble;

	UPROPERTY()
	FAxeHitPlayerForVO OnAxeHitPlayer;

	TArray<UNiagaraComponent> SparkComponents;
	TMap<UNiagaraComponent, bool> SparkCompIsActive;

	int SparkCompsActive = 0;

	FVector SwingDelta;
	FVector LocationLastFrame;

	bool bPlayedFeedback;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ProngRoot.GetChildrenComponentsByClass(UNiagaraComponent, false, SparkComponents);
		for(auto Comp : SparkComponents)
		{
			SparkCompIsActive.Add(Comp, false);
		}

		PlayerHitTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnteredTrigger");
		LocationLastFrame = ProngRoot.WorldLocation;
	}

	UFUNCTION()
	private void OnPlayerEnteredTrigger(AHazePlayerCharacter Player)
	{
		if(!Player.HasControl())
			return;

		if(Player.IsPlayerDead())
			return;

		CrumbRagdollPlayer(Player);
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbRagdollPlayer(AHazePlayerCharacter Player)
	{
		auto AxeComp = USummitTopDownSwingingAxePlayerHitComponent::Get(Player);
		
		FVector SwingVelocity = SwingDelta / Time::GetActorDeltaSeconds(Player);

		bool bIsSwingingToRight = SwingVelocity.DotProduct(ActorRightVector) > 0;
		FVector SwingImpulse;
		if(bIsSwingingToRight)
			SwingImpulse += ActorRightVector * RagdollImpulseSizeSideways[Player];
		else
			SwingImpulse -= ActorRightVector * RagdollImpulseSizeSideways[Player];
		SwingImpulse += ActorUpVector * RagdollImpulseSizeUpwards[Player];

		AxeComp.AxeImpulse.Set(SwingImpulse);
		AxeComp.KillPlaneHeight = ActorLocation.Z + PlayerKillPlaneHeightOffset;
		AxeComp.Axe = this;

		Player.PlayForceFeedback(PassByRumble, false, false, this, 3.0);

		OnAxeHitPlayer.Broadcast(Player);
	}	

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(bReverseSwing)
			MeshComp.RelativeRotation = FRotator(0, 0, SwingMaxAngle);
		else
			MeshComp.RelativeRotation = FRotator(0, 0, -SwingMaxAngle);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		FVector GroundPlaneLocation = ActorLocation + FVector::UpVector * GroundHeightOffset;

		Debug::DrawDebugPlane(GroundPlaneLocation, FVector::UpVector, 200, 2000, FLinearColor::Black, 0);
		Debug::DrawDebugString(GroundPlaneLocation, "Ground Height", FLinearColor::Black);

		FVector KillPlaneLocation = ActorLocation + FVector::UpVector * PlayerKillPlaneHeightOffset;

		Debug::DrawDebugPlane(KillPlaneLocation, FVector::UpVector, 2000, 4000, FLinearColor::Red, 0);
		Debug::DrawDebugString(KillPlaneLocation, "Player Death Height", FLinearColor::Red);
		
		if(bVisualizeSwingInEditor)
			Swing();
		else
		{
			if(bReverseSwing)
				MeshComp.RelativeRotation = FRotator(0, 0, SwingMaxAngle);
			else
				MeshComp.RelativeRotation = FRotator(0, 0, -SwingMaxAngle);
		}

	}
#endif

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Swing();
		SwingDelta = ProngRoot.WorldLocation - LocationLastFrame;
		LocationLastFrame = ProngRoot.WorldLocation;

		for(auto SparkComp : SparkComponents)
		{
			const float GroundHeight = ActorLocation.Z + GroundHeightOffset;

			if(SparkComp.WorldLocation.Z < GroundHeight)
				ToggleSparkComp(SparkComp, true);
			else
				ToggleSparkComp(SparkComp, false);
		}
	}

	private void ToggleSparkComp(UNiagaraComponent SparkComp, bool bToggleOn)
	{
		if(bToggleOn)
		{
			if(SparkCompIsActive[SparkComp])
				return;

			SparkComp.Activate(false);
			SparkCompsActive++;
			if(SparkCompsActive == 1)
				USummitTopDownSwingingAxeEventHandler::Trigger_OnReachedGround(this);
			SparkCompIsActive[SparkComp] = true;

			float MaxDistance = 800.0;

			for (AHazePlayerCharacter Player : Game::Players)
			{
				FVector Location = ActorLocation + FVector(0,0,GroundHeightOffset);
				float Distance = (Player.ActorLocation - Location).Size();
				
				float Multiplier = Math::Saturate(MaxDistance / Distance);
				if (Multiplier < 0.1)
					Multiplier = 0.0;

				Player.PlayForceFeedback(PassByRumble, false, false, this, 0.25 * Multiplier);
				Player.PlayCameraShake(PassByCamShake, this, 0.1 * Multiplier);
			}
		}
		else
		{
			if(!SparkCompIsActive[SparkComp])
				return;

			SparkComp.Deactivate();
			SparkCompsActive--;
			if(SparkCompsActive == 0)
				USummitTopDownSwingingAxeEventHandler::Trigger_OnLeftGround(this);
			SparkCompIsActive[SparkComp] = false;
		}
	}

	private void Swing() const
	{
		float CosAngle = Math::Cos((Time::PredictedGlobalCrumbTrailTime * TWO_PI) / SwingDuration) * SwingMaxAngle;
		if(bReverseSwing)
			CosAngle *= -1;
		MeshComp.RelativeRotation = FRotator(0, 0, CosAngle);
	}
};