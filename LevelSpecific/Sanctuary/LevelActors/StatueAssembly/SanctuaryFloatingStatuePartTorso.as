class ASanctuaryFloatingStatuePartTorso : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TargetTransformComp1;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TargetTransformComp2;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TargetTransformComp3;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TargetTransformComp4;


	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PivotPointComp;

	UPROPERTY(DefaultComponent, Attach = PivotPointComp)
	UPlayerInheritMovementComponent InheritMovementComp;


	UPROPERTY(DefaultComponent, Attach = PivotPointComp)
	USceneComponent AttachmentSlotComp1;

	UPROPERTY(DefaultComponent, Attach = AttachmentSlotComp1)
	UArrowComponent SlotArrow1;
	default SlotArrow1.RelativeRotation = FRotator(0.0, 180.0, 0.0);
	default SlotArrow1.ArrowColor = FLinearColor::Purple;


	UPROPERTY(DefaultComponent, Attach = PivotPointComp)
	USceneComponent AttachmentSlotComp2;

	UPROPERTY(DefaultComponent, Attach = AttachmentSlotComp2)
	UArrowComponent SlotArrow2;
	default SlotArrow2.RelativeRotation = FRotator(0.0, 180.0, 0.0);
	default SlotArrow2.ArrowColor = FLinearColor::Yellow;

	UPROPERTY(DefaultComponent, Attach = AttachmentSlotComp2)
	UDarkPortalTargetComponent DarkPortalTargetComponent2;
	default DarkPortalTargetComponent2.MaximumDistance = 2500;


	UPROPERTY(DefaultComponent, Attach = PivotPointComp)
	USceneComponent AttachmentSlotComp3;

	UPROPERTY(DefaultComponent, Attach = AttachmentSlotComp3)
	UArrowComponent SlotArrow3;
	default SlotArrow3.RelativeRotation = FRotator(0.0, 180.0, 0.0);
	default SlotArrow3.ArrowColor = FLinearColor::Yellow;

	UPROPERTY(DefaultComponent, Attach = AttachmentSlotComp3)
	UDarkPortalTargetComponent DarkPortalTargetComponent3;
	default DarkPortalTargetComponent3.MaximumDistance = 2500;


	UPROPERTY(DefaultComponent, Attach = PivotPointComp)
	USceneComponent AttachmentSlotComp4;

	UPROPERTY(DefaultComponent, Attach = AttachmentSlotComp4)
	UArrowComponent SlotArrow4;
	default SlotArrow4.RelativeRotation = FRotator(0.0, 180.0, 0.0);
	default SlotArrow4.ArrowColor = FLinearColor::Yellow;

	UPROPERTY(DefaultComponent, Attach = AttachmentSlotComp4)
	UDarkPortalTargetComponent DarkPortalTargetComponent4;
	default DarkPortalTargetComponent4.MaximumDistance = 2500;


	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent DarkPortalResponseComponent;


	UPROPERTY(Category = TimeLikes, EditAnywhere)
	FHazeTimeLike RepellTimeLike1;

	UPROPERTY(Category = TimeLikes, EditAnywhere)
	FHazeTimeLike RepellTimeLike2;

	UPROPERTY(Category = TimeLikes, EditAnywhere)
	FHazeTimeLike RepellTimeLike3;

	UPROPERTY(Category = TimeLikes, EditAnywhere)
	FHazeTimeLike RepellTimeLike4;


	UPROPERTY(Category = Settings)
	UForceFeedbackEffect ForceFeedbackEffect;

	UPROPERTY(Category = Settings, EditInstanceOnly)
	ASanctuaryFloatingStatuePart Part1;

	UPROPERTY(Category = Settings, EditInstanceOnly)
	ASanctuaryFloatingStatuePart Part2;

	UPROPERTY(Category = Settings, EditInstanceOnly)
	ASanctuaryFloatingStatuePart Part3;

	UPROPERTY(Category = Settings, EditInstanceOnly)
	ASanctuaryFloatingStatuePart Part4;

	UPROPERTY(EditInstanceOnly)
	ARespawnPoint RespawnPoint;

	UPROPERTY(EditInstanceOnly)
	ARespawnPoint RespawnPoint2;

	FVector RepellStartLocation;
	FRotator RepellStartRotation;

	ADarkPortalActor PortalActor;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DarkPortalResponseComponent.OnGrabbed.AddUFunction(this, n"OnGrabbed");
		Part1.DarkPortalResponseComponent.OnGrabbed.AddUFunction(this, n"OnGrabbed");
		RepellTimeLike1.BindUpdate(this, n"RepellUpdate1");
		RepellTimeLike1.BindFinished(this, n"RepellFinished1");
		RepellTimeLike2.BindUpdate(this, n"RepellUpdate2");
		RepellTimeLike2.BindFinished(this, n"RepellFinished2");
		RepellTimeLike3.BindUpdate(this, n"RepellUpdate3");
		RepellTimeLike3.BindFinished(this, n"RepellFinished3");
		RepellTimeLike4.BindUpdate(this, n"RepellUpdate4");
		RepellTimeLike4.BindFinished(this, n"RepellFinished4");
		Part1.DragTimeLike.BindFinished(this, n"DragFinished1");
		Part2.DragTimeLike.BindFinished(this, n"DragFinished2");
		Part3.DragTimeLike.BindFinished(this, n"DragFinished3");
		Part4.DragTimeLike.BindFinished(this, n"DragFinished4");
		Part2.DarkPortalTargetComponent.Disable(this);
		Part3.DarkPortalTargetComponent.Disable(this);
		Part4.DarkPortalTargetComponent.Disable(this);
		DarkPortalTargetComponent2.Disable(this);
		DarkPortalTargetComponent3.Disable(this);
		DarkPortalTargetComponent4.Disable(this);
		RepellStartLocation = PivotPointComp.WorldLocation;
		RepellStartRotation = PivotPointComp.WorldRotation;
	}

	UFUNCTION()
	private void OnGrabbed(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		PortalActor = UDarkPortalUserComponent::Get(Game::Zoe).Portal;

		if (TargetComponent == Part1.DarkPortalTargetComponent)
		{
			Part1.DarkPortalTargetComponent.Disable(this);
			Part1.DragStartLocation = Part1.AttachmentPlugComp.WorldLocation;
			Part1.DragStartRotation = Part1.AttachmentPlugComp.WorldRotation;
			Part1.DragEndLocation = AttachmentSlotComp1.WorldLocation;
			Part1.DragEndRotation = AttachmentSlotComp1.WorldRotation;
			Part1.DragTimeLike.Play();
		}

		if (TargetComponent == DarkPortalTargetComponent2)
		{
			DarkPortalTargetComponent2.Disable(this);
			Part2.DragStartLocation = Part2.AttachmentPlugComp.WorldLocation;
			Part2.DragStartRotation = Part2.AttachmentPlugComp.WorldRotation;
			Part2.DragEndLocation = AttachmentSlotComp2.WorldLocation;
			Part2.DragEndRotation = AttachmentSlotComp2.WorldRotation;
			Part2.DragTimeLike.Play();
		}

		if (TargetComponent == DarkPortalTargetComponent3)
		{
			DarkPortalTargetComponent3.Disable(this);
			Part3.DragStartLocation = Part3.AttachmentPlugComp.WorldLocation;
			Part3.DragStartRotation = Part3.AttachmentPlugComp.WorldRotation;
			Part3.DragEndLocation = AttachmentSlotComp3.WorldLocation;
			Part3.DragEndRotation = AttachmentSlotComp3.WorldRotation;
			Part3.DragTimeLike.Play();
		}

		if (TargetComponent == DarkPortalTargetComponent4)
		{
			DarkPortalTargetComponent4.Disable(this);
			Part4.DragStartLocation = Part4.AttachmentPlugComp.WorldLocation;
			Part4.DragStartRotation = Part4.AttachmentPlugComp.WorldRotation;
			Part4.DragEndLocation = AttachmentSlotComp4.WorldLocation;
			Part4.DragEndRotation = AttachmentSlotComp4.WorldRotation;
			Part4.DragTimeLike.Play();
		}
	}


	UFUNCTION()
	void DragFinished1()
	{
		Game::Mio.PlayForceFeedback(ForceFeedbackEffect, false, true, this);
		Game::Zoe.PlayForceFeedback(ForceFeedbackEffect, false, true, this);

		Part1.AttachmentPlugComp.AttachToComponent(AttachmentSlotComp1);

		if (IsValid(PortalActor))
			PortalActor.RequestDespawn();

		PortalActor.RequestDespawn();

		if (IsValid(RespawnPoint))
		{
			Game::Mio.SetStickyRespawnPoint(RespawnPoint);
			Game::Zoe.SetStickyRespawnPoint(RespawnPoint);
		}

		RepellTimeLike1.Play();
	}

	UFUNCTION()
	void DragFinished2()
	{
		Game::Mio.PlayForceFeedback(ForceFeedbackEffect, false, true, this);
		Game::Zoe.PlayForceFeedback(ForceFeedbackEffect, false, true, this);

		Part2.AttachmentPlugComp.AttachToComponent(AttachmentSlotComp2);

		PortalActor.RequestDespawn();

		RepellTimeLike2.Play();
	}

	UFUNCTION()
	void DragFinished3()
	{
		Game::Mio.PlayForceFeedback(ForceFeedbackEffect, false, true, this);
		Game::Zoe.PlayForceFeedback(ForceFeedbackEffect, false, true, this);

		Part3.AttachmentPlugComp.AttachToComponent(AttachmentSlotComp3);

		PortalActor.RequestDespawn();
		
		RepellTimeLike3.Play();
	}

	UFUNCTION()
	private void DragFinished4()
	{
		Game::Mio.PlayForceFeedback(ForceFeedbackEffect, false, true, this);
		Game::Zoe.PlayForceFeedback(ForceFeedbackEffect, false, true, this);

		Part4.AttachmentPlugComp.AttachToComponent(AttachmentSlotComp4);

		PortalActor.RequestDespawn();

		Game::Mio.BlockCapabilities(n"Respawn", this);
		Game::Zoe.BlockCapabilities(n"Respawn", this);

		RepellTimeLike4.Play();
	}


	UFUNCTION()
	private void RepellUpdate1(float Alpha)
	{
		FVector Location = Math::Lerp(RepellStartLocation, TargetTransformComp1.WorldLocation, Alpha);
		FRotator Rotaion = Math::LerpShortestPath(RepellStartRotation, TargetTransformComp1.WorldRotation, Alpha);
		PivotPointComp.SetWorldLocationAndRotation(Location, Rotaion);
	}

	UFUNCTION()
	private void RepellFinished1()
	{
		PrintToScreenScaled("Finished", 1.0);
		
		DarkPortalTargetComponent2.Enable(this);
	}

	UFUNCTION()
	private void RepellUpdate2(float Alpha)
	{
		FVector Location = Math::Lerp(TargetTransformComp1.WorldLocation, TargetTransformComp2.WorldLocation, Alpha);
		FRotator Rotaion = Math::LerpShortestPath(TargetTransformComp1.WorldRotation, TargetTransformComp2.WorldRotation, Alpha);
		PivotPointComp.SetWorldLocationAndRotation(Location, Rotaion);
	}

	UFUNCTION()
	private void RepellFinished2()
	{
		PrintToScreenScaled("Finished", 1.0);
		
		DarkPortalTargetComponent3.Enable(this);
	}

	UFUNCTION()
	private void RepellUpdate3(float Alpha)
	{
		FVector Location = Math::Lerp(TargetTransformComp2.WorldLocation, TargetTransformComp3.WorldLocation, Alpha);
		FRotator Rotaion = Math::LerpShortestPath(TargetTransformComp2.WorldRotation, TargetTransformComp3.WorldRotation, Alpha);
		PivotPointComp.SetWorldLocationAndRotation(Location, Rotaion);
	}

	UFUNCTION()
	private void RepellFinished3()
	{
		PrintToScreenScaled("Finished", 1.0);
		
		DarkPortalTargetComponent4.Enable(this);
	}

	UFUNCTION()
	private void RepellUpdate4(float Alpha)
	{
		FVector Location = Math::Lerp(TargetTransformComp3.WorldLocation, TargetTransformComp4.WorldLocation, Alpha);
		FRotator Rotaion = Math::LerpShortestPath(TargetTransformComp3.WorldRotation, TargetTransformComp4.WorldRotation, Alpha);
		PivotPointComp.SetWorldLocationAndRotation(Location, Rotaion);
	}

	UFUNCTION()
	private void RepellFinished4()
	{
		Game::Mio.UnblockCapabilities(n"Respawn", this);
		Game::Zoe.UnblockCapabilities(n"Respawn", this);

		if (IsValid(RespawnPoint2))
		{
			Game::Mio.SetStickyRespawnPoint(RespawnPoint2);
			Game::Zoe.SetStickyRespawnPoint(RespawnPoint2);
		}
	}
};