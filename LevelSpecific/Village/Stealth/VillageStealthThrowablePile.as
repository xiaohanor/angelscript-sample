class AVillageStealthThrowablePile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent InteractionRoot;

	UPROPERTY(DefaultComponent, Attach = InteractionRoot)
	UInteractionComponent InteractionComp;
	default InteractionComp.bPlayerCanCancelInteraction = false;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PileRoot;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent CapabilityRequestComp;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ThrowForceFeedback;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AVillageStealthThrowable> ThrowableClass;

	UPROPERTY(EditDefaultsOnly)
	FText ThrowTutorialText;

	UPROPERTY(EditAnywhere)
	bool bLeftSide = false;

	UPROPERTY(EditAnywhere)
	float ThrowDistance = 1400.0;

	UPROPERTY(EditInstanceOnly)
	AStaticCameraActor CameraActor;

	UPROPERTY(EditInstanceOnly)
	AVillageStealthOgre TargetOgre;

	UPROPERTY(EditAnywhere)
	UAnimSequence EnterAnim;

	UPROPERTY(EditAnywhere)
	UAnimSequence MhAnim;

	UPROPERTY(EditAnywhere)
	UAnimSequence CancelAnim;

	UPROPERTY(EditAnywhere)
	UAnimSequence ThrowAnim;

	UPROPERTY(EditAnywhere)
	UAnimSequence ThrownMhAnim;

	UPROPERTY(EditAnywhere)
	UAnimSequence ExitAnim;

	UPROPERTY(EditAnywhere)
	float ZoeCancelBlendTime = 0.5;

	UPROPERTY(EditAnywhere)
	float ZoeThrownExitBlendTime = 0.5;
}