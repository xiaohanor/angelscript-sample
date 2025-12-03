struct FCameraFollowSplineRotationData
{
	access Internal = private, UCameraFollowSplineRotationComponent;

	UHazeSplineComponent Spline = nullptr;
	FCameraFollowSplineRotationSettings Settings;

	FCameraFollowSplineRotationData(UHazeSplineComponent InSpline, FCameraFollowSplineRotationSettings InSettings)
	{
		Spline = InSpline;
		Settings = InSettings;
	}
};

struct FCameraFollowSplineRotationSettings
{
	/**
	 * If we moved more than this along the spline in one frame, we will not follow the spline rotation.
	 * This prevents snapping the camera when skipping parts of the spline.
	 */
	UPROPERTY()
	float SplineDistanceThreshold = 100;

	/**
	 * If true, we always try to look towards the spline forward.
	 * If false, we will try to look towards the closest direction.
	 */
	UPROPERTY()
	bool bAlwaysFaceForward = true;
};

UCLASS(NotBlueprintable)
class UCameraFollowSplineRotationComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	private TInstigated<FCameraFollowSplineRotationData> FollowSplineRotationDatas;
	private TSet<FInstigator> BlockingInstigators;

	private AHazePlayerCharacter Player;
	UCameraUserComponent CameraUserComp;

	private uint PreviousSampleFrame = 0;
	private FRotator PreviousRotation;
	private float PreviousSplineDistance;

	private float BlendInDuration = 0;
	private float BlendOutDuration = 0;
	private FHazeAcceleratedFloat AccBlendAlpha;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		CameraUserComp = UCameraUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(PreviousSampleFrame < Time::FrameNumber - 1)
		{
			// If we didn't sample last frame, reset the previous frames data
			// to prevent snapping
			SetPreviousSplineDistanceAndRotation();
		}

		if(!HasSplineToFollow() || IsBlocked())
		{
			AccBlendAlpha.AccelerateTo(0, BlendOutDuration, DeltaSeconds);

			if(AccBlendAlpha.Value < KINDA_SMALL_NUMBER)
			{
				StopFollowing();
				return;
			}
		}
		else if(HasSplineToFollow())
		{
			AccBlendAlpha.AccelerateTo(1, BlendInDuration, DeltaSeconds);
		}

		float CurrentSplineDistance = 0;
		FRotator CurrentRotation = FRotator::ZeroRotator;
		GetSplineDistanceAndRotation(CurrentSplineDistance, CurrentRotation);

		const float SplineDistanceDelta = Math::Abs(CurrentSplineDistance - PreviousSplineDistance);
		if(SplineDistanceDelta > GetSplineDistanceThreshold())
		{
			// We have traveled too far from the last frame, following the spline could cause a nasty snap
		}
		else
		{
			// Follow the rotation of the spline
			FRotator Delta = CurrentRotation - PreviousRotation;
			AddWorldRotationDelta(Delta);
		}

		SetPreviousSplineDistanceAndRotation();
	}

	bool IsActive()
	{
		if(IsBlocked())
			return false;

		if(!HasSplineToFollow())
			return false;

		if(!IsComponentTickEnabled())
			return false;

		return true;
	}

	void Apply(FCameraFollowSplineRotationData Data, FInstigator Instigator, float BlendDuration = 1, EInstigatePriority Priority = EInstigatePriority::Low)
	{
		if(!devEnsure(Data.Spline != nullptr, "Null Spline passed to UCameraFollowSplineRotationComponent::Apply()!"))
			return;

		UHazeSplineComponent PreviouslyFollowing = GetSpline();

		FollowSplineRotationDatas.Apply(Data, Instigator, Priority);

		bool bIsFollowing = HasSplineToFollow();

		if(PreviouslyFollowing == nullptr && bIsFollowing)
		{
			StartBlendingIn(BlendDuration);
			StartFollowing();
		}
		else if(PreviouslyFollowing != GetSpline())
		{
			StartBlendingIn(BlendDuration);
			OnChangeSpline();
		}
	}

	void Clear(FInstigator Instigator, float BlendDuration = -1)
	{
		UHazeSplineComponent PreviouslyFollowing = GetSpline();

		FollowSplineRotationDatas.Clear(Instigator);

		if(!HasSplineToFollow())
		{
			StartBlendingOut(BlendDuration);
		}
		else if(PreviouslyFollowing != GetSpline())
		{
			StartBlendingIn(BlendDuration);
			OnChangeSpline();
		}
	}

	void Block(FInstigator Instigator, float BlendDuration)
	{
		bool bWasBlocked = IsBlocked();
		BlockingInstigators.Add(Instigator);
		if(!bWasBlocked)
			StartBlendingOut(BlendDuration);
	}

	void Unblock(FInstigator Instigator, float BlendDuration)
	{
		bool bWasBlocked = IsBlocked();
		BlockingInstigators.Remove(Instigator);
		if(bWasBlocked && !IsBlocked())
		{
			StartFollowing();
			StartBlendingIn(BlendDuration);
		}
	}

	bool IsBlocked() const
	{
		return !BlockingInstigators.IsEmpty();
	}

	bool HasSplineToFollow() const
	{
		if(FollowSplineRotationDatas.IsDefaultValue())
			return false;

		return true;
	}

	private void StartFollowing()
	{
		SetComponentTickEnabled(true);
		SetPreviousSplineDistanceAndRotation();
	}

	private void StopFollowing()
	{
		SetComponentTickEnabled(false);
	}

	private void OnChangeSpline()
	{
		// Reset the previous data to prevent snapping the rotation
		SetPreviousSplineDistanceAndRotation();
	}

	private void StartBlendingIn(float BlendDuration)
	{
		if(BlendDuration <= 0)
			AccBlendAlpha.SnapTo(1);
		else
			AccBlendAlpha.SnapTo(0);
		
		BlendInDuration = BlendDuration;
	}
	
	private void StartBlendingOut(float BlendDuration)
	{
		BlendOutDuration = BlendDuration;
	}

	void SetPreviousSplineDistanceAndRotation()
	{
		PreviousSampleFrame = Time::FrameNumber;
		GetSplineDistanceAndRotation(PreviousSplineDistance, PreviousRotation);
	}

	private void GetSplineDistanceAndRotation(float&out SplineDistance, FRotator& SplineRotation) const
	{
		auto Spline = GetSpline();
		if(Spline == nullptr)
			return;
		
		SplineDistance = Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);
		SplineRotation = Spline.GetWorldRotationAtSplineDistance(SplineDistance).Rotator();
	}

	private void AddWorldRotationDelta(FRotator Delta) const
	{
		// Don't apply if the player has disabled camera assistance
		if(!Player.IsUsingCameraAssist())
			return;

		FRotator LocalDelta = CameraUserComp.WorldToLocalRotation(Delta);
		CameraUserComp.AddDesiredRotation(LocalDelta * AccBlendAlpha.Value, this);
	}

	UHazeSplineComponent GetSpline() const
	{
		return FollowSplineRotationDatas.Get().Spline;
	}

	float GetSplineDistanceThreshold() const
	{
		return FollowSplineRotationDatas.Get().Settings.SplineDistanceThreshold;
	}

	bool GetAlwaysFaceForward() const
	{
		return FollowSplineRotationDatas.Get().Settings.bAlwaysFaceForward;
	}
};