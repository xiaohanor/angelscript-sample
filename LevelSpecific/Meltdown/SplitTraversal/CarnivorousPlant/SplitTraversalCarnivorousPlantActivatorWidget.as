class USplitTraversalCarnivorousPlantActivatorWidget : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	UOverlay TargetOverlay;

	UPROPERTY(BindWidget)
	UImage TargetBorders;

	UPROPERTY(BindWidget)
	UImage Crosshair;

	ASplitTraversalCarnivorousPlantActivator Activator;

	FHazeAcceleratedVector2D AccLocation;
	FHazeAcceleratedFloat AccScaleDownMultiplier;
	float ScaleDownAmount = 0.3;
	float StandStillDuration = 0.15;
	float ScaleUpDuration = 0.8;
	float ScaleDownDuration = 0.5;
	float TimeStoodStill = 0;

	bool bFollowEnabled = true;
	float StartFollowTime = 0;

	bool bIsControlled = false;

	UPROPERTY(BlueprintReadOnly)
	bool bWidgetActivated = false;
	
	bool bShouldHaveTarget = false;

	UPROPERTY(BlueprintReadOnly)
	protected bool bHasTarget = true;

	UPROPERTY(BlueprintReadOnly)
	bool bHasFoundTargetOnce = false;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		AccLocation.SnapTo(FVector2D::UnitVector * 0.5);
		AccScaleDownMultiplier.SnapTo(1);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if(bFollowEnabled)
		{
			FTransform CamTransform = Activator.Plant.CaptureComp.WorldTransform;
			FHazeViewParameters ViewParams;
			ViewParams.Location = CamTransform.Location;
			ViewParams.Rotation = CamTransform.Rotator();
			ViewParams.FOV = Activator.Plant.CaptureComp.FOVAngle;
			ViewParams.ScreenResolution = FVector2D(512, 512);
			FHazeComputedView PlayerView = SceneView::ComputeView(ViewParams);

			FVector2D ScreenUV;

			FVector ZoePos = ASplitTraversalManager::GetSplitTraversalManager().Position_FantasyToScifi(Game::Zoe.ActorLocation);
			PlayerView.ProjectWorldToViewUV(ZoePos, ScreenUV);


			float AccelerationDuration = 0.1;

			if(Time::GetGameTimeSince(StartFollowTime) < 1)
				AccelerationDuration = 1;

			AccLocation.AccelerateTo(ScreenUV * FVector2D(500, 600), AccelerationDuration, InDeltaTime);
		}
		else
		{
			AccLocation.AccelerateTo(FVector2D(250, 300), 0.1, InDeltaTime);
		}

		if(Math::IsNearlyZero(UHazeMovementComponent::Get(Game::Zoe).Velocity.Size()))
		{
			TimeStoodStill += InDeltaTime;
			
			if(TimeStoodStill > StandStillDuration)
				AccScaleDownMultiplier.AccelerateTo(1, ScaleDownDuration, InDeltaTime);
		}
		else
		{
			TimeStoodStill = 0;
			AccScaleDownMultiplier.AccelerateTo(0, ScaleUpDuration, InDeltaTime);
		}

		if(bIsControlled)
		{
			if(bShouldHaveTarget != bHasTarget)
			{
				bHasTarget = bShouldHaveTarget;
				if(bHasTarget)
					BP_OnRegainTarget();
				else
					BP_OnLostTarget();
			}
		}

		Cast<UCanvasPanelSlot>(TargetOverlay.Slot).SetPosition(AccLocation.Value);
		TargetBorders.SetRenderScale(FVector2D::UnitVector * 1 - AccScaleDownMultiplier.Value * ScaleDownAmount);
	}

	UFUNCTION()
	void SetScreenActivated()
	{
		if(bIsControlled)
			bWidgetActivated = true;
	}

	UFUNCTION(BlueprintEvent)
	void OnStartControlling(bool _bShouldHaveTarget)
	{
		bShouldHaveTarget = _bShouldHaveTarget;
		bIsControlled = true;
		Timer::SetTimer(this, n"SetScreenActivated", 0.75);

		if(_bShouldHaveTarget)
			bHasFoundTargetOnce = true;
	}

	UFUNCTION(BlueprintEvent)
	void OnStopControlling()
	{
		bIsControlled = false;
		bWidgetActivated = false;
	}

	UFUNCTION(BlueprintEvent)
	void DisableCrosshair(){}

	UFUNCTION(BlueprintEvent)
	private void BP_OnBite(){}

	UFUNCTION(BlueprintEvent)
	private void BP_OnLostTarget(){}

	UFUNCTION(BlueprintEvent)
	private void BP_OnRegainTarget(){}

	UFUNCTION(BlueprintEvent)
	private void BP_RegainSignal(){}

	void OnBite()
	{
		BP_OnBite();
		bFollowEnabled = false;
	}

	void EnableFollow()
	{
		bFollowEnabled = true;
		StartFollowTime = Time::GameTimeSeconds;
	}

	void TargetFound()
	{
		if(bWidgetActivated)
			BP_OnRegainTarget();
		else
		{
			BP_RegainSignal();
			bHasTarget = true;
		}

		bShouldHaveTarget = true;
		bHasFoundTargetOnce = true;
	}
}