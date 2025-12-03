class UGravityBikeSplineJumpSettings : UHazeComposableSettings
{
	UPROPERTY(EditAnywhere, Category = "Jump")
	bool bAllowJumping = true;
	
	UPROPERTY(EditAnywhere, Category = "Jump")
	bool bCanApplyJumpImpulse = true;

	UPROPERTY(EditAnywhere, Category = "Jump")
	float JumpImpulse = 2250;

	UPROPERTY(EditAnywhere, Category = "Jump")
	float PitchImpulse = 1000;

	UPROPERTY(EditAnywhere, Category = "Jump|Limits")
	bool bLimitSplineUpVelocity = true;

	UPROPERTY(EditAnywhere, Category = "Jump|Limits")
	float MaxSplineUpVelocity = 2500;

	UPROPERTY(EditAnywhere, Category = "Jump|Limits")
	bool bLimitJumpDirectionVelocity = true;

	UPROPERTY(EditAnywhere, Category = "Jump|Limits")
	float MaxJumpDirectionVelocity = 2500;

	UPROPERTY(EditAnywhere, Category = "Jump|Limits")
	bool bAllowJumpImpulseBackwards = false;
};

namespace GravityBikeSpline::Jump
{
	const FName GravityBikeSplineJump = n"GravityBikeSplineJump";
}