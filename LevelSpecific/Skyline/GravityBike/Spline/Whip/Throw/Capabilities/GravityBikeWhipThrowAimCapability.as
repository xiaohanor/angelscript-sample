#if !RELEASE
namespace DevToggleGravityBikeSpline
{
	const FHazeDevToggleBool LockTargetOnStartThrow;
};
#endif

class UGravityBikeWhipThrowAimCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(GravityBikeSpline::Tags::GravityBikeSpline);
	default CapabilityTags.Add(GravityBikeWhip::Tags::GravityBikeWhip);
	default CapabilityTags.Add(GravityBikeWhip::Tags::GravityBikeWhipAim);

	default TickGroup = EHazeTickGroup::BeforeGameplay;
	default TickGroupOrder = 110;

	UGravityBikeWhipComponent WhipComp;
	UPlayerAimingComponent AimComp;
	UPlayerTargetablesComponent PlayerTargetables;
	UPlayerMovementComponent MoveComp;

	float TimeWithoutInput = 0;

	bool bHadThrowTarget = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WhipComp = UGravityBikeWhipComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Player);
		PlayerTargetables = UPlayerTargetablesComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);

#if !RELEASE
		DevToggleGravityBikeSpline::LockTargetOnStartThrow.MakeVisible();
#endif
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!WhipComp.HasGrabbedAnything())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!WhipComp.HasGrabbedAnything())
			return true;

		return false;	
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bHadThrowTarget = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		WhipComp.SetThrowTarget(nullptr);
		MoveComp.ClearGravityDirectionOverride(this);
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!HasControl())
			return;

		if(ActiveDuration < KINDA_SMALL_NUMBER)
		{
			// bIsGivingAimInput is true by default, but we force it off for the first frame
			return;
		}

		// Aiming input is handled by the default 2D aiming input capabilities

		UpdateInput(DeltaTime);

		UpdateTarget();
	}

	void UpdateInput(float DeltaTime)
	{
		if(IsActivelyGivingInput())
		{
			TimeWithoutInput = 0;
		}
		else
		{
			TimeWithoutInput += DeltaTime;
		}
	}

	void UpdateTarget()
	{
		check(HasControl());
		
		UGravityBikeWhipThrowTargetComponent NewTarget = PlayerTargetables.GetPrimaryTarget(UGravityBikeWhipThrowTargetComponent);

		// We can't unset the target if we are currently throwing
		if(WhipComp.IsThrowing())
		{
#if !RELEASE
			if(DevToggleGravityBikeSpline::LockTargetOnStartThrow.IsEnabled())
			{
				if(WhipComp.GetThrowTarget() != nullptr)
					bHadThrowTarget = true;

				// While throwing, we don't allow switching targets at all, but we allow going from no target to having a target
				if(bHadThrowTarget)
					return;
			}
			else
#endif
			{
				// Don't allow unsetting
				if(NewTarget == nullptr)
					return;
			}
		}

		if(IsActivelyGivingInput())
		{
			if(WhipComp.GetThrowTarget() != NewTarget)
			{
				// Replace our current target
				WhipComp.CrumbSetThrowTarget(NewTarget);
			}
		}
		else
		{
			if(TimeWithoutInput < GravityBikeWhip::ThrowTargetBufferTime)
			{
				// We are buffering the input, don't switch target unless we have no valid targets!
				if(NewTarget == nullptr && WhipComp.GetThrowTarget() != nullptr)
				{
					WhipComp.CrumbSetThrowTarget(nullptr);
				}
			}
			else
			{
				// We are not giving any input, no targets are valid!
				if(WhipComp.GetThrowTarget() != nullptr)
				{
					WhipComp.CrumbSetThrowTarget(nullptr);
				}
			}
		}
	}

	bool IsActivelyGivingInput() const
	{
		return AimComp.GetPlayerAimingRay().bIsGivingAimInput;
	}
}