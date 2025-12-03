UCLASS(Abstract)
class ATundraPlayerTreeGuardianActor : AHazeCharacter
{
	default CapsuleComponent.CollisionProfileName = n"NoCollision";
	default Mesh.ShadowPriority = EShadowPriority::Player;

	/* Where the roots will originate when grappling with left hand */
	UPROPERTY(DefaultComponent, Attach=CharacterMesh0, AttachSocket = LeftHand)
	USceneComponent GrappleLeftRootsOrigin;

	/* Where the roots will originate when grappling with right hand */
	UPROPERTY(DefaultComponent, Attach=CharacterMesh0, AttachSocket = RightHand)
	USceneComponent GrappleRightRootsOrigin;

	UPROPERTY(DefaultComponent)
	UPlayerTreeGuardianStepComponent StepComponent;

	UPROPERTY(DefaultComponent)
	UHazeMovementAudioComponent MoveAudioComponent;
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintPure)
	UNiagaraComponent GetRangedLifeGiverVFX_RightHand() 
	{
		auto FoundComp = GetComponent( UNiagaraComponent, n"VFX_Roots_LifeGiver_RightHand");
		UNiagaraComponent VFX = Cast<UNiagaraComponent>(FoundComp);
		return VFX;
	}

	UFUNCTION(BlueprintPure)
	UNiagaraComponent GetRangedLifeGiverVFX_Chest() 
	{
		auto FoundComp = GetComponent( UNiagaraComponent, n"VFX_Roots_LifeGiver_Chest");
		UNiagaraComponent VFX = Cast<UNiagaraComponent>(FoundComp);
		return VFX;
	}

	UFUNCTION(BlueprintPure)
	UNiagaraComponent GetRangedLifeGiverVFX_LeftHand() 
	{
		auto FoundComp = GetComponent( UNiagaraComponent, n"VFX_Roots_LifeGiver_LeftHand");
		UNiagaraComponent VFX = Cast<UNiagaraComponent>(FoundComp);
		return VFX;
	}

}

namespace Treeguardian
{
	namespace Grapple
	{
		namespace AnimationDelays
		{
			const float GrowingRoots = 0.45;
			const float GrowingRootsWhenAttached = 0.2;
			const float MovingAfterGrowingRoots = 0.4;
			const float MovingAfterGrowingRootsWhenAttached = 0.05;
			const float GrowingTakedownRoots = 0.2;
		}
	}

	namespace Takedown
	{
		namespace AnimationDelays
		{
			const float Launch = 0.3;
		}
	}
}