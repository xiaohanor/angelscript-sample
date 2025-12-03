UCLASS(Abstract)
class UAnimInstanceGameShowArenaAnnouncer : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	AGameShowArenaAnnouncer Announcer;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	UGameShowArenaAnnouncerFaceComponent AnnouncerFaceComp;

	UPROPERTY(BlueprintReadOnly, Interp)
	float LowerPistonExtend = 0;

	UPROPERTY(BlueprintReadOnly, Interp)
	float UpperPistonExtend = 0;

	UPROPERTY(BlueprintReadOnly, Interp)
	float BaseTwist = 0;

	UPROPERTY(BlueprintReadOnly, Interp)
	float BodyRotation = 0;

	UPROPERTY(BlueprintReadOnly, Interp)
	FQuat BodyRotationQuat = FQuat::Identity;

	UPROPERTY(BlueprintReadOnly, Interp)
	FVector IKArm8CtrlLocation = FVector::ZeroVector;

	UPROPERTY(BlueprintReadOnly, Interp)
	FTransform IKArm13Ctrl = FTransform::Identity;

	UFUNCTION(BlueprintOverride)
	void BlueprintPostEvaluateAnimation()
	{
		if (AnnouncerFaceComp != nullptr)
			AnnouncerFaceComp.UpdateFace();
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Announcer = Cast<AGameShowArenaAnnouncer>(HazeOwningActor);
		if (Announcer != nullptr)
			AnnouncerFaceComp = UGameShowArenaAnnouncerFaceComponent::Get(Announcer);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Announcer == nullptr)
		{
			Announcer = Cast<AGameShowArenaAnnouncer>(Outer.Outer);
			if (Announcer == nullptr)
				return;
		}

		LowerPistonExtend = Announcer.LowerPistonExtend;
		UpperPistonExtend = Announcer.UpperPistonExtend;
		BaseTwist = Announcer.BaseTwist;
		IKArm8CtrlLocation = Announcer.IKArm8CtrlLocation;
		IKArm13Ctrl = Announcer.IKArm13Ctrl;
		BodyRotation = Announcer.BodyRotation;
		AnnouncerFaceComp.UpdateFace();
	}
};