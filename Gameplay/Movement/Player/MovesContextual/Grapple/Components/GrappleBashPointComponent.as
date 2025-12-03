UCLASS(Meta = (EditorSpriteTexture = "/Game/Gameplay/Movement/ContextualMoves/ContextualMovesEditorTexture/LaunchPointIconBillboardGradient.LaunchPointIconBillboardGradient", EditorSpriteOffset=""))
class UGrappleBashPointComponent : UGrapplePointBaseComponent
{
	default TargetableCategory = n"ContextualMoves";
	default UsableByPlayers = EHazeSelectPlayer::Both;
	default GrappleType = EGrapplePointVariations::BashPoint;
	default ActivationRange = 900.0;
	default MinimumRange = 0.0;

	UPROPERTY(EditAnywhere, Meta = (ShowOnlyInnerProperties))
	FGrappleBashPointSettings Settings;

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		if (!VerifyBaseTargetableConditions(Query))
			return false;
		
		if (!VerifyBaseGrappleConditions(Query))
			return false;

		if (Query.DistanceToTargetable > Settings.QuickEnterDistance)
			Targetable::ScoreLookAtAim(Query);

		Targetable::ApplyVisibleRange(Query, ActivationRange + AdditionalVisibleRange);
		Targetable::ApplyTargetableRangeWithBuffer(Query, ActivationRange, ActivationBufferRange);
		Targetable::ApplyVisualProgressFromRange(Query, ActivationRange + AdditionalVisibleRange, ActivationRange, ActivationBufferRange);

		if (bTestCollision)
		{
			// Avoid tracing if we are already lower score than the current primary target
			if (!Query.IsCurrentScoreViableForPrimary())
				return false;
			return Targetable::RequireNotOccludedFromCamera(Query, bIgnoreOwnerCollision = bIgnorePointOwner);
		}

		return true;
	}

}

enum EGrappleBashAimDirectionMode
{
	// Restrict aim based off the direction that the player entered in
	PlayerEnterDirection,
	// Restrict aim based off the *opposite* direction the player entered in
	PlayerOppositeDirection,
	// Restrict aim based off the grapple bash point's forward direction
	BashPointForwardDirection,
};

struct FGrappleBashPointSettings
{
	// How fast does the bash launch
	UPROPERTY(EditAnywhere, Category = "Grapple Bash")
	float LaunchImpulse = 1500.0;

	// Extra impulse that launches us upwards regardless of where we aim
	UPROPERTY(EditAnywhere, Category = "Grapple Bash")
	float BaseUpwardsImpulse = 800.0;

	// Upwards angle (degrees) from the point (3D Perspective Only)
	UPROPERTY(EditAnywhere, Category = "Grapple Bash")
	float UpwardsLaunchAngle = 45.0;

	// How to determine the bash point's aiming restriction
	UPROPERTY(EditAnywhere, Category = "Grapple Bash")
	EGrappleBashAimDirectionMode AimDirectionMode = EGrappleBashAimDirectionMode::PlayerEnterDirection;

	// Maximum angle to deviate from the aim direction
	UPROPERTY(EditAnywhere, Category = "Grapple Bash")
	float MaximumAimAngle = 180.0;

	// If we're at this distance from the grapple bash, do the quick enter instead of the grapple
	UPROPERTY(EditAnywhere, Category = "Grapple Bash")
	float QuickEnterDistance = 200.0;
}