// ======================================================================== //
// Copyright 2009-2017 Intel Corporation                                    //
//                                                                          //
// Licensed under the Apache License, Version 2.0 (the "License");          //
// you may not use this file except in compliance with the License.         //
// You may obtain a copy of the License at                                  //
//                                                                          //
//     http://www.apache.org/licenses/LICENSE-2.0                           //
//                                                                          //
// Unless required by applicable law or agreed to in writing, software      //
// distributed under the License is distributed on an "AS IS" BASIS,        //
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. //
// See the License for the specific language governing permissions and      //
// limitations under the License.                                           //
// ======================================================================== //

#include "sg/common/Animator.h"

namespace ospray {
  namespace sg {

   SGVar lerp(float interp, const SGVar& value1, const SGVar& value2)
   {
     return interp*(1.f-value1.get<float>())+interp*value2.get<float>();
   }

    Animator::Animator()
    {
      setValue(0.f);
      createChild("start", "float", 0.f);
      createChild("stop", "float", 1.f);
    }

    void Animator::preCommit(RenderContext &ctx)
    {
      if (!hasParent())
        return;
      if (!hasChild("value1")) //TODO: support moving it?
      {
        const std::string type = parent().type();
        createChild("value1", type);
        createChild("value2", type);
        setValue(parent().value());
      }
      std::cout << "setting value: " << valueAs<float>() << std::endl;
      parent().setValue(value());
    }

    void Animator::postCommit(RenderContext &ctx)
    {
    }

    void Animator::preTraverse(RenderContext &ctx, const std::string& operation, bool& traverseChildren)
    {
      Node::preTraverse(ctx,operation, traverseChildren);
      if (operation == "animate")
      {
        const SGVar& value1 = child("value1").value();
        const SGVar& value2 = child("value2").value();
        const float start = child("start").valueAs<float>();
        const float stop = child("stop").valueAs<float>();
        const float duration = stop-start;
        float interp = (ctx.time-start)/duration;
        setValue(lerp(interp, value1, value2));
      }
    }


    OSP_REGISTER_SG_NODE(Animator);

  } // ::ospray::sg
} // ::ospray

