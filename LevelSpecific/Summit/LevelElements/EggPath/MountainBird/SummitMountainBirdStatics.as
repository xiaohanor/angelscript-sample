namespace SummitMountainBird
{
	namespace Animations
	{
		void PlayIdleAnimation(AAISummitMountainBird MountainBird)
		{
			FHazePlaySlotAnimationParams PlayAnimParams;
			PlayAnimParams.Animation = MountainBird.IdleAnimation;
			PlayAnimParams.BlendType = EHazeBlendType::BlendType_Inertialization;
			PlayAnimParams.BlendTime = 1.0;			
			PlayAnimParams.bLoop = true;
			MountainBird.PlaySlotAnimation(PlayAnimParams);
		}

		void PlayTakeOffAnimation(AAISummitMountainBird MountainBird)
		{
			FHazePlaySlotAnimationParams PlayAnimParams;
			PlayAnimParams.Animation = MountainBird.TakeOffAnimation;
			PlayAnimParams.BlendType = EHazeBlendType::BlendType_Inertialization;
			PlayAnimParams.BlendTime = 1.0;
			PlayAnimParams.bLoop = false;
			MountainBird.PlaySlotAnimation(PlayAnimParams);
		}

		void PlayLandAnimation(AAISummitMountainBird MountainBird)
		{
			FHazePlaySlotAnimationParams PlayAnimParams;
			PlayAnimParams.Animation = MountainBird.LandAnimation;
			PlayAnimParams.BlendType = EHazeBlendType::BlendType_Inertialization;
			PlayAnimParams.BlendTime = 1.0;
			PlayAnimParams.bLoop = false;
			MountainBird.PlaySlotAnimation(PlayAnimParams);
		}

		void PlayFlapAnimation(AAISummitMountainBird MountainBird)
		{
			if (MountainBird.IsPlayingAnyLoopingAnimationOnSlot(EHazeSlotAnimType::SlotAnimType_Default))
				return;
			FHazePlaySlotAnimationParams PlayAnimParams;
			PlayAnimParams.Animation = MountainBird.FlapAnimation;
			PlayAnimParams.BlendType = EHazeBlendType::BlendType_Inertialization;
			PlayAnimParams.BlendTime = 1.0;
			PlayAnimParams.bLoop = true;
			MountainBird.PlaySlotAnimation(PlayAnimParams,);
		}

		void PlayGlideAnimation(AAISummitMountainBird MountainBird)
		{
			FHazePlaySlotAnimationParams PlayAnimParams;
			PlayAnimParams.Animation = MountainBird.GlideAnimation;
			PlayAnimParams.BlendType = EHazeBlendType::BlendType_Inertialization;
			PlayAnimParams.BlendTime = 1.0;
			PlayAnimParams.bLoop = false;
			MountainBird.PlaySlotAnimation(PlayAnimParams);
		}

		void PlayFlyAwayAnimation(AAISummitMountainBird MountainBird)
		{
			FHazePlaySlotAnimationParams PlayAnimParams;
			PlayAnimParams.Animation = MountainBird.FlyAwayAnimation;
			PlayAnimParams.BlendType = EHazeBlendType::BlendType_Inertialization;
			PlayAnimParams.BlendTime = 1.0;			
			PlayAnimParams.bLoop = false;
			MountainBird.PlaySlotAnimation(PlayAnimParams);
		}

	}
}