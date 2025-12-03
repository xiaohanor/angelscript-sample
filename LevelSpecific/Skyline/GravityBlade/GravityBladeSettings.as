namespace GravityBlade
{
	const FName DebugCategory = n"GravityBlade";
	const FName AttachSocket = n"RightAttach";

	const FName SheathedAttachSocket = n"GravityBladeSocket";
	const FTransform SheathedAttachTransform = FTransform(
		FRotator(0, 0, 0),
		FVector(0, 0, 0),
	);
	const float SheatheLerpDuration = 0.1;
	const float UnsheatheLerpDuration = 0.1;
}

namespace GravityBladeTags
{
	const FName GravityBlade = n"GravityBlade";
	const FName GravityBladeWield = n"GravityBladeWield";
	const FName GravityBladeAttackTrace = n"GravityBladeAttackTrace";

	const FName GravityBladeCamera = n"GravityBladeCamera";
	const FName GravityBladeAnimation = n"GravityBladeAnimation";
	const FName GravityBladeAim = n"GravityBladeAim";
}