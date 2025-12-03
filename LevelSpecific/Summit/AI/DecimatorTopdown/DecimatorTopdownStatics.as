mixin bool IsOverlappingPlayer(const AAISummitDecimatorTopdown Decimator, const AHazePlayerCharacter Player)
{
	UCapsuleComponent PlayerCapsule = Player.CapsuleComponent;
	FTransform Transform = Decimator.SpinchargeCapsuleComponent.WorldTransform;
	
	bool bIsIntersecting = Overlap::QueryShapeOverlap(
		FCollisionShape::MakeSphere(Decimator.SpinchargeCapsuleComponent.CapsuleRadius), Transform,
		FCollisionShape::MakeCapsule(PlayerCapsule.CapsuleRadius, PlayerCapsule.CapsuleHalfHeight), PlayerCapsule.WorldTransform
	);

	//Debug::DrawDebugSphere(Transform.Location, Decimator.SpinchargeCapsuleComponent.CapsuleRadius, bDrawInForeground = true);
	
	return bIsIntersecting;
}

namespace DecimatorTopdown
{
	AAISummitDecimatorTopdown GetDecimator()
	{
		TListedActors<AAISummitDecimatorTopdown> Decimator;
		check(Decimator.Num() > 0);
		return Decimator.GetSingle();
	}

	namespace Collision
	{
		void SetPlayerBlockingCollision(AAISummitDecimatorTopdown Decimator)
		{
			UHazeCapsuleCollisionComponent CapsuleComp = Decimator.CapsuleComponent;
			CapsuleComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);
			UCapsuleComponent BlockPlayerCapsuleComp = Decimator.BlockPlayerCapsuleComponent;
			BlockPlayerCapsuleComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);
		}

		void SetPlayerIgnoreCollision(AAISummitDecimatorTopdown Decimator)
		{
			UHazeCapsuleCollisionComponent CapsuleComp = Decimator.CapsuleComponent;
			CapsuleComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Ignore);
			UCapsuleComponent BlockPlayerCapsuleComp = Decimator.BlockPlayerCapsuleComponent;
			BlockPlayerCapsuleComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Ignore);
		}

#if !RELEASE
		void DebugDrawBlockingCollision(AAISummitDecimatorTopdown Decimator)
		{
			UHazeCapsuleCollisionComponent CapsuleComp = Decimator.CapsuleComponent;
			ECollisionResponse CapsuleResponse = CapsuleComp.GetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter);
			if (CapsuleResponse == ECollisionResponse::ECR_Block)
				Debug::DrawDebugCapsule(CapsuleComp.WorldLocation, CapsuleComp.CapsuleHalfHeight, CapsuleComp.CapsuleRadius, CapsuleComp.WorldRotation, bDrawInForeground = true);

			UCapsuleComponent BlockPlayerCapsuleComp = Decimator.BlockPlayerCapsuleComponent;
			ECollisionResponse BlockPlayerCapsuleResponse = BlockPlayerCapsuleComp.GetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter);
			if (BlockPlayerCapsuleResponse == ECollisionResponse::ECR_Block)
				Debug::DrawDebugCapsule(BlockPlayerCapsuleComp.WorldLocation, BlockPlayerCapsuleComp.CapsuleHalfHeight, BlockPlayerCapsuleComp.CapsuleRadius, BlockPlayerCapsuleComp.WorldRotation, bDrawInForeground = true);
		}
#endif
	}
	
	namespace Spikebomb
	{
		// Get decimators explosion trail spawn pool, used by all spikebombs.
		UHazeActorLocalSpawnPoolComponent GetSpikebombExplosionTrailSpawnPool()
		{
			AAISummitDecimatorTopdown Decimator = GetDecimator();
			return Decimator.ExplosionTrailSpawnPool;
		}
	}


	namespace Animation
	{
		namespace Durations
		{
			const float Roar = 4.333;
			const float SpearSpawning = 0.00;
			const float SpikeBombSpawning = 0.00;
			const float ArenaEnterJump = 0.00;
			const float ShockwaveJumps = 0.00;
		}

		// Default locomotion in phase 3
		void SetFeatureBaseMovementTagToSpinning(UBasicAIAnimationComponent AnimComp)
		{
			AnimComp.BaseMovementTag = FeatureTagSummitDecimator::Spin;
		}

		// Default locomotion in phase 1 and 2
		void ClearFeatureBaseMovementTag(UBasicAIAnimationComponent AnimComp)
		{
			AnimComp.BaseMovementTag = n"None";
		}

		void RequestFeatureRoar(UBasicAIAnimationComponent AnimComp, FInstigator Instigator)
		{
			AnimComp.RequestFeature(FeatureTagSummitDecimator::Magic, SubTagSummitDecimatorMagic::Magic3, EBasicBehaviourPriority::High, Instigator);
		}
		
		void RequestFeatureSpearSpawning(UBasicAIAnimationComponent AnimComp, FInstigator Instigator)
		{
			AnimComp.RequestFeature(FeatureTagSummitDecimator::Magic, SubTagSummitDecimatorMagic::Magic2, EBasicBehaviourPriority::High, Instigator);
		}
		
		void RequestFeatureSpikeBombSpawning(UBasicAIAnimationComponent AnimComp, FInstigator Instigator)
		{
			AnimComp.RequestFeature(FeatureTagSummitDecimator::Magic, SubTagSummitDecimatorMagic::Magic1, EBasicBehaviourPriority::High, Instigator);
		}
		
		// Called when turn-jumping into spawning attack on balcony.
		void RequestFeatureTurn(UBasicAIAnimationComponent AnimComp, FInstigator Instigator)
		{
			AnimComp.RequestFeature(FeatureTagSummitDecimator::Turn, FeatureTagSummitDecimator::Turn, EBasicBehaviourPriority::Medium, Instigator);
		}

		void RequestFeatureTurnJump(UBasicAIAnimationComponent AnimComp, FInstigator Instigator)
		{
			AnimComp.RequestFeature(FeatureTagSummitDecimator::TurnJump, FeatureTagSummitDecimator::TurnJump, EBasicBehaviourPriority::Medium, Instigator);
		}
		
		void RequestFeatureLocomotion(UBasicAIAnimationComponent AnimComp, FInstigator Instigator)
		{
			AnimComp.RequestFeature(FeatureTagSummitDecimator::Locomotion, FeatureTagSummitDecimator::Locomotion, EBasicBehaviourPriority::Medium, Instigator);
		}
		
		// Called when turning towards arena and jumping in.
		void RequestFeatureEnterPhaseThree(UBasicAIAnimationComponent AnimComp, FInstigator Instigator)
		{
			AnimComp.RequestFeature(FeatureTagSummitDecimator::Spin, EBasicBehaviourPriority::High, Instigator);
		}

		// Called when entering spincharge attack or recovering from knockdown
		void RequestFeatureSpinStart(UBasicAIAnimationComponent AnimComp, FInstigator Instigator)
		{
			AnimComp.RequestFeature(FeatureTagSummitDecimator::Spin, SubTagSummitDecimatorAttack::SpinStart, EBasicBehaviourPriority::Medium, Instigator);
		}
		
		// Called when getting knocked down
		void RequestFeatureSpinStop(UBasicAIAnimationComponent AnimComp, FInstigator Instigator)
		{
			AnimComp.RequestFeature(FeatureTagSummitDecimator::Spin, SubTagSummitDecimatorAttack::SpinStop, EBasicBehaviourPriority::Medium, Instigator);
		}
				
		void RequestFeatureTakeDamage(UBasicAIAnimationComponent AnimComp, FInstigator Instigator)
		{
			AnimComp.RequestFeature(FeatureTagSummitDecimator::Spin, SubTagSummitDecimatorAttack::SpinStopTakeDamage, EBasicBehaviourPriority::Medium, Instigator);
		}
		
		void RequestFeatureShockwaveJumps(UBasicAIAnimationComponent AnimComp, FInstigator Instigator)
		{
			AnimComp.RequestFeature(FeatureTagSummitDecimator::Spin, SubTagSummitDecimatorAttack::SpinJump, EBasicBehaviourPriority::Medium, Instigator);
		}

		void RequestFeaturePush(UBasicAIAnimationComponent AnimComp, FInstigator Instigator)
		{
			AnimComp.RequestFeature(FeatureTagSummitDecimator::Spin, SubTagSummitDecimatorAttack::Push, EBasicBehaviourPriority::Medium, Instigator);
		}

		void RequestFeaturePushPanic(UBasicAIAnimationComponent AnimComp, FInstigator Instigator)
		{
			AnimComp.RequestFeature(FeatureTagSummitDecimator::Spin, SubTagSummitDecimatorAttack::PushPanic, EBasicBehaviourPriority::Medium, Instigator);
		}

	}

}