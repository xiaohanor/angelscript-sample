enum EDanceShowdownPose
{
	None = 0,
	
	Up = 1,
	Right = 2,
	Down = 3,
	Left = 4
}

namespace DanceShowdown
{

	EDanceShowdownPose GetPoseFromInput(float X, float Y, bool bUseAutoAimCheat)
	{
		if(X == 0 && Y == 0)
			return EDanceShowdownPose::None;

		if(bUseAutoAimCheat)
		{
			const EDanceShowdownPose TargetPose = DanceShowdown::GetManager().PoseManager.CurrentPose;

			switch(TargetPose)
			{
				case EDanceShowdownPose::Right:
					if(X > 1 - DanceShowdown::InputAutoAimAngle)
						return TargetPose;
					break;

				case EDanceShowdownPose::Left:
					if(X < -1 + DanceShowdown::InputAutoAimAngle)
						return TargetPose;
					break;

				case EDanceShowdownPose::Down:
					if(Y > 1 - DanceShowdown::InputAutoAimAngle)
						return TargetPose;
					break;

				case EDanceShowdownPose::Up:
					if(Y < -1 + DanceShowdown::InputAutoAimAngle)
						return TargetPose;
					break;

				default:
					break;
			}
		}
			
		if(Math::Abs(X) > Math::Abs(Y))
		{
			if(X < 0)
				return EDanceShowdownPose::Left;
			return EDanceShowdownPose::Right;
		}
		else
		{
			if(Y < 0)
				return EDanceShowdownPose::Up;
			return EDanceShowdownPose::Down;
		}
	}
}