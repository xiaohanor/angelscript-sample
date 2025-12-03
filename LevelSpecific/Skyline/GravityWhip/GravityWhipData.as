enum EGravityWhipGrabMode
{
	Drag,
	Sling,
	Control,
	ControlledDrag,

	GloryKill,

	TorHammer,
}

struct FGravityWhipGrabData
{
	UPROPERTY(BlueprintReadOnly)
	UGravityWhipTargetComponent TargetComponent;
	UPROPERTY(BlueprintReadOnly)
	UPrimitiveComponent HighlightPrimitive;
	UPROPERTY(BlueprintReadOnly)
	EGravityWhipGrabMode GrabMode;
	UPROPERTY(BlueprintReadOnly)
	FGravityWhipTargetAudioData AudioData;
}

struct FGravityWhipReleaseData
{
	UPROPERTY(BlueprintReadOnly)
	UGravityWhipTargetComponent TargetComponent;
	UPROPERTY(BlueprintReadOnly)
	UPrimitiveComponent HighlightPrimitive;
	UPROPERTY(BlueprintReadOnly)
	FVector Impulse;
	UPROPERTY(BlueprintReadOnly)
	FGravityWhipTargetAudioData AudioData;
}

struct FGravityWhipAnimationData
{
	UPROPERTY(BlueprintReadOnly)	
	EGravityWhipGrabMode LastGrabMode;
	UPROPERTY(BlueprintReadOnly)
	uint LastGrabFrame;
	UPROPERTY(BlueprintReadOnly)
	uint LastGrabAttachFrame;
	UPROPERTY(BlueprintReadOnly)
	uint LastReleaseFrame;
	UPROPERTY(BlueprintReadOnly)
	uint LastAirGrabFrame;
	UPROPERTY(BlueprintReadOnly)
	float HorizontalAimSpace;
	UPROPERTY(BlueprintReadOnly)
	float VerticalAimSpace;
	UPROPERTY(BlueprintReadOnly)
	FVector2D PullDirection;
	UPROPERTY(BlueprintReadOnly)
	bool bIsThrowing;
	UPROPERTY(BlueprintReadOnly)
	int NumGrabs;
	UPROPERTY()	
	bool bIsRequestingWhip;
	UPROPERTY()	
	bool bHasTurnedIntoWhipHit;
	UPROPERTY()	
	float WhipToMhDelay = 0.75;
	UPROPERTY(BlueprintReadOnly)
	TArray<UGravityWhipTargetComponent> TargetComponents;

	UPROPERTY(BlueprintReadOnly)
	float Tension = 0;

	UPROPERTY(BlueprintReadOnly)
	FVector TensionPullDirection = FVector::ZeroVector;

	UPROPERTY(BlueprintReadOnly)
	FVector2D TensionPullDirection2D = FVector2D::ZeroVector;

	bool GrabbedThisFrame() const
	{
		return (LastGrabFrame == Time::FrameNumber);
	}

	bool GrabAttachedThisFrame() const
	{
		return (LastGrabAttachFrame == Time::FrameNumber);
	}

	bool ReleasedThisFrame() const
	{
		if (LastReleaseFrame != Time::FrameNumber)
			return false;

		if (LastGrabMode == EGravityWhipGrabMode::Sling)
			return false;

		return true;
	}
	
	bool ThrownThisFrame() const
	{
		if (LastReleaseFrame != Time::FrameNumber)
			return false;

		if (LastGrabMode != EGravityWhipGrabMode::Sling)
			return false;

		return true;
	}

	bool AirGrabbedThisFrame() const
	{
		return (LastAirGrabFrame == Time::FrameNumber);
	}
}