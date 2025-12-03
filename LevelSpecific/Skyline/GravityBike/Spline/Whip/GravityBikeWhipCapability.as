class UGravityBikeWhipCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(GravityBikeSpline::Tags::GravityBikeSpline);
	default CapabilityTags.Add(GravityBikeWhip::Tags::GravityBikeWhip);

	default TickGroup = EHazeTickGroup::Input;

	UGravityBikeWhipComponent WhipComp;
	UGravityBikeSplinePlayerComponent BikeComp;

	FVector2D CursorUV;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WhipComp = UGravityBikeWhipComponent::Get(Player);
		BikeComp = UGravityBikeSplinePlayerComponent::Get(Player);

		// Start blocked to ensure that we are mounted before any of the other capabilities run
		Player.BlockCapabilities(GravityBikeWhip::Tags::GravityBikeWhip, this);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		WhipComp.Reset();
		
		WhipComp.GravityBike = BikeComp.GravityBike;
		Player.UnblockCapabilities(GravityBikeWhip::Tags::GravityBikeWhip, this);

		if(HasControl())
		{
			const FVector2D Input = GetAttributeVector2D(AttributeVectorNames::RightStickRaw);
			WhipComp.Input.SetValue(Input);
		}

		CursorUV = FVector2D(0.5, 0.5);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.BlockCapabilities(GravityBikeWhip::Tags::GravityBikeWhip, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
			HandleInput();

		InterpInput(WhipComp.Input.Value, DeltaTime);
	}

	private void HandleInput()
	{
		check(HasControl());
		FVector2D Input = GetAttributeVector2D(AttributeVectorNames::RightStickRaw);
		Input = Input.GetClampedToMaxSize(1.0);
		WhipComp.Input.SetValue(Input);
	}

	private void InterpInput(FVector2D Input, float DeltaTime)
	{
		const bool bIsInputting = !Input.IsNearlyZero();
		if(bIsInputting)
		{
			WhipComp.SmoothInput = Math::Vector2DInterpTo(WhipComp.SmoothInput, Input, DeltaTime, 7);
		}
		else
		{
			WhipComp.SmoothInput = Math::Vector2DInterpTo(WhipComp.SmoothInput, Input, DeltaTime, 12);
		}
	}
};