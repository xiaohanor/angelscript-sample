class ASanctuaryFloatingStatuePart : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PivotPointComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TargetTransformComp;

	UPROPERTY(DefaultComponent, Attach = PivotPointComp)
	USceneComponent AttachmentPlugComp;

	UPROPERTY(DefaultComponent, Attach = AttachmentPlugComp)
	UPlayerInheritMovementComponent InheritMovementComp;
	default InheritMovementComp.TriggeredByPlayers = EHazeSelectPlayer::None;

	UPROPERTY(DefaultComponent, Attach = AttachmentPlugComp)
	UArrowComponent PlugArrow;
	default PlugArrow.ArrowColor = FLinearColor::Yellow;

	UPROPERTY(DefaultComponent, Attach = AttachmentPlugComp)
	USceneComponent AttachmentSlotComp;

	UPROPERTY(DefaultComponent, Attach = AttachmentSlotComp)
	UArrowComponent SlotArrow;
	default SlotArrow.RelativeRotation = FRotator(0.0, 180.0, 0.0);
	default SlotArrow.ArrowColor = FLinearColor::Purple;

	UPROPERTY(DefaultComponent, Attach = AttachmentPlugComp)
	UDarkPortalTargetComponent DarkPortalTargetComponent;
	default DarkPortalTargetComponent.MaximumDistance = 2500;

	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent DarkPortalResponseComponent;

	UPROPERTY(EditInstanceOnly)
	ARespawnPoint RespawnPoint;

	UPROPERTY(Category = TimeLikes, EditAnywhere)
	FHazeTimeLike DragTimeLike;

	UPROPERTY(Category = TimeLikes, EditAnywhere)
	FHazeTimeLike RepellTimeLike;


	UPROPERTY(Category = Settings)
	UForceFeedbackEffect ForceFeedbackEffect;

	UPROPERTY(Category = Settings, EditInstanceOnly)
	ASanctuaryFloatingStatuePart ParentPartActor;

	FVector DragStartLocation;
	FRotator DragStartRotation;

	FVector DragEndLocation;
	FRotator DragEndRotation;

	FVector RepellStartLocation;
	FRotator RepellStartRotation;

	FVector RepellEndLocation;
	FRotator RepellEndRotation;

	ADarkPortalActor PortalActor;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (IsValid(ParentPartActor))
		{
			DarkPortalResponseComponent.OnGrabbed.AddUFunction(this, n"OnGrabbed");
		}
		
		DragTimeLike.BindUpdate(this, n"DragUpdate");
		DragTimeLike.BindFinished(this, n"DragFinished");

		RepellTimeLike.BindUpdate(this, n"RepellUpdate");
		RepellTimeLike.BindFinished(this, n"RepellFinished");

		RepellStartLocation = PivotPointComp.WorldLocation;
		RepellStartRotation = PivotPointComp.WorldRotation;

		RepellEndLocation = TargetTransformComp.WorldLocation;
		RepellEndRotation = TargetTransformComp.WorldRotation;
	}

	UFUNCTION()
	private void OnGrabbed(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		PortalActor = UDarkPortalUserComponent::Get(Game::Zoe).Portal;
		
		DragStartLocation = AttachmentPlugComp.WorldLocation;
		DragStartRotation = AttachmentPlugComp.WorldRotation;
		DragEndLocation = ParentPartActor.AttachmentSlotComp.WorldLocation;
		DragEndRotation = ParentPartActor.AttachmentSlotComp.WorldRotation;
		DarkPortalTargetComponent.Disable(this);
		DragTimeLike.Play();
	}

	UFUNCTION()
	private void DragUpdate(float Alpha)
	{
		FVector Location = Math::Lerp(DragStartLocation, DragEndLocation, Alpha);
		FRotator Rotaion = Math::LerpShortestPath(DragStartRotation, DragEndRotation, Alpha);
		AttachmentPlugComp.SetWorldLocationAndRotation(Location, Rotaion);
	}

	UFUNCTION()
	private void DragFinished()
	{
		Game::Mio.PlayForceFeedback(ForceFeedbackEffect, false, true, this);
		Game::Zoe.PlayForceFeedback(ForceFeedbackEffect, false, true, this);

		AttachmentPlugComp.AttachToComponent(ParentPartActor.AttachmentSlotComp);

		PortalActor.RequestDespawn();

		ParentPartActor.InheritMovementComp.SetComponentTickEnabled(true);
		ParentPartActor.RepellTimeLike.Play();
	}

	UFUNCTION()
	private void RepellUpdate(float Alpha)
	{
		FVector Location = Math::Lerp(RepellStartLocation, RepellEndLocation, Alpha);
		FRotator Rotaion = Math::LerpShortestPath(RepellStartRotation, RepellEndRotation, Alpha);
		PivotPointComp.SetWorldLocationAndRotation(Location, Rotaion);
	}

	UFUNCTION()
	private void RepellFinished()
	{
		if (IsValid(RespawnPoint))
		{
			Game::Mio.SetStickyRespawnPoint(RespawnPoint);
			Game::Zoe.SetStickyRespawnPoint(RespawnPoint);
		}
	}
};