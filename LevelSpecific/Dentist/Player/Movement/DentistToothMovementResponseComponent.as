enum EDentistToothBounceResponseType
{
	Bounce,
	Dash,
	GroundPound,
};

enum EDentistToothBounceNormal
{
	AlwaysUp,
	ActorUp,
	Normal,
};

enum EDentistToothDashImpactResponse
{
	Disabled,
	Bounce,
	Backflip,
};

event void FDentistToothOnBouncedOnEvent(AHazePlayerCharacter Player, EDentistToothBounceResponseType Type, FHitResult Impact);
event void FDentistToothOnDashedInto(AHazePlayerCharacter DashPlayer, FVector Impulse, FHitResult Impact);
event void FDentistToothOnGroundPoundedOn(AHazePlayerCharacter GroundPoundPlayer, FHitResult Impact);

UCLASS(NotBlueprintable, HideCategories = "ComponentTick Debug Activation Cooking Tags Navigation Disable")
class UDentistToothMovementResponseComponent : UActorComponent
{
	access Bounce = private, UDentistToothBounceCapability, UDentistToothDashMovementResolver, UDentistToothGroundPoundDropCapability;
	/**
	 * Bounce
	 */

	// Should the player bounce when it lands on us?
	UPROPERTY(EditAnywhere, Category = "Bounce")
	bool bBounceOnImpact = false;

	UPROPERTY(BlueprintReadOnly, Category = "Bounce")
	FDentistToothOnBouncedOnEvent OnBouncedOn;

	UPROPERTY(EditAnywhere, Category = "Bounce", Meta = (EditCondition = "bBounceOnImpact", EditConditionHides))
	EDentistToothBounceNormal BounceNormal = EDentistToothBounceNormal::AlwaysUp;


	UPROPERTY(EditAnywhere, Category = "Dash")
	EDentistToothDashImpactResponse OnDashImpact = EDentistToothDashImpactResponse::Disabled;

	UPROPERTY(EditAnywhere, Category = "Dash|Bounce", Meta = (EditCondition = "OnDashImpact == EDentistToothDashImpactResponse::Bounce", EditConditionHides))
	float DashBounceVerticalImpulse = 1000;

	UPROPERTY(EditAnywhere, Category = "Dash|Bounce", Meta = (EditCondition = "OnDashImpact == EDentistToothDashImpactResponse::Bounce", EditConditionHides))
	EDentistToothBounceNormal DashBounceNormal = EDentistToothBounceNormal::ActorUp;

	UPROPERTY(EditAnywhere, Category = "Dash|Backflip", Meta = (EditCondition = "OnDashImpact == EDentistToothDashImpactResponse::Backflip", EditConditionHides))
	float BackflipDuration = 1;

	UPROPERTY(EditAnywhere, Category = "Dash|Backflip", Meta = (EditCondition = "OnDashImpact == EDentistToothDashImpactResponse::Backflip", EditConditionHides))
	float BackflipHorizontalImpulse = 1000;

	UPROPERTY(EditAnywhere, Category = "Dash|Backflip", Meta = (EditCondition = "OnDashImpact == EDentistToothDashImpactResponse::Backflip", EditConditionHides))
	float BackflipVerticalImpulse = 500;

	UPROPERTY(EditAnywhere, Category = "Ground Pound|Bounce")
	bool bBounceOnGroundPoundImpact = false;

	UPROPERTY(EditAnywhere, Category = "Ground Pound|Bounce", Meta = (EditCondition = "bBounceOnGroundPoundImpact", EditConditionHides))
	float GroundPoundBounceImpulse = 2000;

	UPROPERTY(EditAnywhere, Category = "Ground Pound|Bounce", Meta = (EditCondition = "bBounceOnGroundPoundImpact", EditConditionHides))
	bool bGroundPoundRemoveHorizontalVelocity = true;

	UPROPERTY(EditAnywhere, Category = "Ground Pound|Bounce", Meta = (EditCondition = "bBounceOnGroundPoundImpact", EditConditionHides))
	EDentistToothBounceNormal GroundPoundBounceNormal = EDentistToothBounceNormal::AlwaysUp;

	/**
	 * Dash
	 */

	UPROPERTY(BlueprintReadOnly, Category = "Dash")
	FDentistToothOnDashedInto OnDashedInto;

	/**
	 * Ground Pound
	 */

	UPROPERTY(BlueprintReadOnly, Category = "Ground Pound")
	FDentistToothOnGroundPoundedOn OnGroundPoundedOn;

	access:Bounce
	bool ShouldBounceFromImpact(EDentistToothBounceResponseType ImpactType) const
	{
		switch(ImpactType)
		{
			case EDentistToothBounceResponseType::Bounce:
				return bBounceOnImpact;

			case EDentistToothBounceResponseType::Dash:
			{
				switch(OnDashImpact)
				{
					case EDentistToothDashImpactResponse::Disabled:
						return false;

					case EDentistToothDashImpactResponse::Bounce:
						return true;

					case EDentistToothDashImpactResponse::Backflip:
						return false;
				}
			}

			case EDentistToothBounceResponseType::GroundPound:
				return bBounceOnGroundPoundImpact;
		}
	}

	access:Bounce
	FVector GetBounceNormalForImpactType(FHitResult Impact, EDentistToothBounceResponseType ImpactType) const
	{
		switch(ImpactType)
		{
			case EDentistToothBounceResponseType::Bounce:
				return GetBounceNormal(Impact, BounceNormal);

			case EDentistToothBounceResponseType::Dash:
				return GetBounceNormal(Impact, DashBounceNormal);

			case EDentistToothBounceResponseType::GroundPound:
				return GetBounceNormal(Impact, GroundPoundBounceNormal);
		}
	}

	private FVector GetBounceNormal(FHitResult Impact, EDentistToothBounceNormal Normal) const
	{
		switch (Normal)
		{
			case EDentistToothBounceNormal::AlwaysUp:
				return FVector::UpVector;

			case EDentistToothBounceNormal::ActorUp:
				return Impact.Actor.ActorUpVector;

			case EDentistToothBounceNormal::Normal:
				return Impact.Normal;
		}
	}
};